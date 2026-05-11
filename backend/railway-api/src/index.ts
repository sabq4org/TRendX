import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { randomUUID } from "node:crypto";
import { Prisma } from "@prisma/client";
import { prisma, closeDb } from "./db.js";
import {
  hashPassword,
  makeSalt,
  signToken,
  verifyPassword,
  verifyToken,
} from "./auth.js";
import { snake } from "./lib/snake.js";
import {
  ageGroupFromBirthYear,
  normalizeDevice,
  normalizeGender,
} from "./lib/demographics.js";
import { aiJSON } from "./lib/ai.js";
import { PROMPT_VERSIONS, SYSTEM_PROMPTS } from "./lib/ai-prompts.js";
import {
  giftDTO,
  pollDTO,
  redemptionDTO,
  surveyDTO,
  topicDTO,
  userDTO,
} from "./lib/dto.js";
import {
  getCachedOrComputePoll,
  getCachedOrComputeSurvey,
} from "./lib/analytics.js";
import {
  computeSurveyHeatmap,
  computePollHeatmap,
  computeCrossQuestion,
  getCachedSentimentTimeline,
  getCachedSectorBenchmark,
  type HeatmapDimension,
} from "./lib/deep-analytics.js";
import { computeSurveyPersonas } from "./lib/personas.js";
import {
  dispatchWebhookEvent,
  generateWebhookSecret,
  testWebhook,
} from "./lib/webhooks.js";
import {
  runSnapshotsNow,
  startSnapshotJob,
} from "./jobs/snapshot.js";
import { sseHandler, broadcastEvent } from "./events/sse.js";
import {
  getCurrentPulseForUser,
  getOrCreateTodayPulse,
  previousPulseSummary,
  pulseHistory,
  recordResponse as recordPulseResponse,
} from "./lib/pulse.js";
import { getStreak } from "./lib/streak.js";
import { getCachedOpinionDNA } from "./lib/dna.js";
import {
  estimateAudience,
  listPublisherAudiences,
  createAudience,
  type AudienceCriteria,
} from "./lib/audience.js";
import { getCachedTrendXIndex } from "./lib/index-metrics.js";
import {
  recordPrediction,
  scorePollPredictions,
  userAccuracyStats,
  predictionLeaderboard,
} from "./lib/predictions.js";
import {
  getOrCreateThisWeekChallenge,
  submitChallengePrediction,
  settleChallenge,
} from "./lib/challenges.js";
import {
  listComments,
  postComment,
  voteOnComment,
} from "./lib/comments.js";
import { buildNotifications } from "./lib/notifications.js";
import { normalizeHandle, validateHandle } from "./lib/handle.js";
import { startDailyJob } from "./jobs/daily.js";

// MARK: - Types

type Variables = {
  userId: string;
};

const app = new Hono<{ Variables: Variables }>();

// MARK: - Global middleware

app.use(
  "*",
  cors({
    origin: "*",
    allowMethods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allowHeaders: ["Authorization", "Content-Type"],
  }),
);

// MARK: - Public routes

app.get("/", (c) =>
  c.json({
    service: "trendx-railway-api",
    status: "ok",
    docs: "Public: GET /health, POST /auth/signup, POST /auth/signin. Everything else requires Authorization: Bearer <jwt>.",
    version: "0.2.0",
  }),
);

app.get("/health", (c) => c.json({ ok: true, service: "trendx-railway-api" }));

// MARK: - Auth

app.post("/auth/signup", async (c) => {
  const body = await c.req.json<{
    name?: string;
    email?: string;
    password?: string;
    gender?: string;
    birth_year?: number;
    city?: string;
    region?: string;
    device_type?: string;
    os_version?: string;
  }>();

  const email = (body.email ?? "").trim().toLowerCase();
  const name = (body.name ?? "").trim();
  const password = body.password ?? "";
  if (!email || !password || password.length < 6 || !name) {
    return c.json({ error: "Invalid signup payload" }, 400);
  }

  const salt = makeSalt();
  const passwordHash = await hashPassword(password, salt);

  try {
    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        passwordSalt: salt,
        name,
        avatarInitial: name.slice(0, 1) || "م",
        gender: normalizeGender(body.gender),
        birthYear: body.birth_year ?? null,
        city: body.city ?? null,
        region: body.region ?? null,
        deviceType: normalizeDevice(body.device_type),
        osVersion: body.os_version ?? null,
        ledgerEntries: {
          create: {
            amount: 100,
            type: "signup_bonus",
            description: "رصيد البداية لمستخدم جديد",
            balanceAfter: 100,
          },
        },
      },
    });

    return c.json({
      access_token: signToken({ sub: user.id, email }, requireSecret()),
      refresh_token: null,
      user: userDTO(user),
    });
  } catch (error) {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2002"
    ) {
      return c.json({ error: "Email already registered" }, 409);
    }
    throw error;
  }
});

app.post("/auth/signin", async (c) => {
  const body = await c.req.json<{ email?: string; password?: string }>();
  const email = (body.email ?? "").trim().toLowerCase();

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) return c.json({ error: "Invalid credentials" }, 401);

  const ok = await verifyPassword(
    body.password ?? "",
    user.passwordSalt,
    user.passwordHash,
  );
  if (!ok) return c.json({ error: "Invalid credentials" }, 401);

  await prisma.user.update({
    where: { id: user.id },
    data: { lastActiveAt: new Date() },
  });

  return c.json({
    access_token: signToken({ sub: user.id, email }, requireSecret()),
    refresh_token: null,
    user: userDTO(user),
  });
});

// MARK: - Auth middleware (everything below needs a token)
//
// Tokens accepted via either:
//   - `Authorization: Bearer <jwt>` (preferred, used by iOS + dashboard fetch)
//   - `?token=<jwt>` query param (necessary for SSE / printable reports
//     where the browser cannot attach custom headers).

app.use("*", async (c, next) => {
  const path = c.req.path;
  const isPublic =
    path === "/" ||
    path === "/health" ||
    path.startsWith("/auth/") ||
    path.startsWith("/reports/") || // print-ready HTML reports auth via query
    path.startsWith("/public/") ||  // TRENDX Index public endpoint
    path.startsWith("/embed/") ||   // embeddable widgets
    path === "/widget.js" ||
    path === "/pulse/today/anon" || // unauthenticated pulse preview
    c.req.method === "OPTIONS";
  if (isPublic) return next();

  const header = c.req.header("Authorization") ?? "";
  const headerToken = header.replace(/^Bearer\s+/i, "");
  const queryToken = c.req.query("token");
  const token = headerToken || queryToken;
  if (!token) return c.json({ error: "Missing token" }, 401);

  try {
    const payload = verifyToken(token, requireSecret());
    c.set("userId", payload.sub);
  } catch {
    return c.json({ error: "Invalid or expired token" }, 401);
  }
  return next();
});

async function loadActor(
  c: { get: (k: "userId") => string },
): Promise<{ id: string; role: string; tier: string } | null> {
  const id = c.get("userId");
  const user = await prisma.user.findUnique({
    where: { id },
    select: { id: true, role: true, tier: true },
  });
  return user;
}

// MARK: - Profile

app.get("/profile", async (c) => {
  const user = await prisma.user.findUnique({
    where: { id: c.get("userId") },
  });
  if (!user) return c.json({ error: "Profile not found" }, 404);
  return c.json(userDTO(user));
});

app.post("/profile", async (c) => {
  const body = await c.req.json<{
    name?: string;
    email?: string;
    avatar_initial?: string;
    avatar_url?: string;
    banner_url?: string;
    bio?: string;
    handle?: string;
    phone?: string;
    gender?: string;
    birth_year?: number;
    city?: string;
    region?: string;
    account_type?: "individual" | "organization" | "government";
  }>();

  const updates: Record<string, unknown> = {};
  if (body.name !== undefined) updates.name = body.name;
  if (body.email !== undefined) updates.email = body.email.trim().toLowerCase();
  if (body.avatar_initial !== undefined) updates.avatarInitial = body.avatar_initial;
  if (body.avatar_url !== undefined) updates.avatarUrl = body.avatar_url;
  if (body.banner_url !== undefined) updates.bannerUrl = body.banner_url;
  if (body.bio !== undefined) updates.bio = body.bio;
  if (body.phone !== undefined) updates.phone = body.phone;
  if (body.gender !== undefined) updates.gender = normalizeGender(body.gender);
  if (body.birth_year !== undefined) updates.birthYear = body.birth_year;
  if (body.city !== undefined) updates.city = body.city;
  if (body.region !== undefined) updates.region = body.region;

  // account_type can be self-set to `individual` or `organization` —
  // governments must be promoted by an admin so we filter that out here.
  if (body.account_type === "individual" || body.account_type === "organization") {
    updates.accountType = body.account_type;
  }

  // Handle changes go through the validator (lowercase, format,
  // reserved list, uniqueness).
  if (body.handle !== undefined && body.handle !== null) {
    const check = await validateHandle(body.handle, c.get("userId"));
    if (!check.ok) {
      return c.json({ error: check.message, reason: check.reason }, 400);
    }
    updates.handle = check.handle;
  }

  const user = await prisma.user.update({
    where: { id: c.get("userId") },
    data: updates,
  });
  return c.json(userDTO(user));
});

// MARK: - Handles

/**
 * Cheap availability check used by the profile editor: hits this with
 * the candidate handle on debounce so the user sees green/red as they
 * type. Doesn't actually reserve the handle.
 */
app.get("/handles/check", async (c) => {
  const raw = c.req.query("handle") ?? "";
  if (!raw) return c.json({ ok: false, reason: "invalid", message: "أدخل معرّفاً." }, 200);
  const check = await validateHandle(raw, c.get("userId"));
  return c.json(check);
});

/**
 * Public profile lookup. Accepts either a UUID (`id`) or a handle
 * (`@handle` — leading @ optional). Returns the full userDTO so the
 * profile page can render counts, badges, etc. We keep this on the
 * authed router for now; switch to public when comments / messages
 * launch.
 */
app.get("/users/:idOrHandle", async (c) => {
  const idOrHandle = c.req.param("idOrHandle");
  const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(idOrHandle);
  const user = isUUID
    ? await prisma.user.findUnique({ where: { id: idOrHandle } })
    : await prisma.user.findUnique({ where: { handle: normalizeHandle(idOrHandle) } });
  if (!user) return c.json({ error: "User not found" }, 404);
  return c.json(userDTO(user));
});

// MARK: - Topics

app.get("/topics", async (c) => {
  const userId = c.get("userId");
  const topics = await prisma.topic.findMany({ orderBy: { name: "asc" } });
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { followedTopics: true },
  });
  const followed = new Set(user?.followedTopics ?? []);
  return c.json(
    topics.map((t) => ({
      ...topicDTO(t),
      is_following: followed.has(t.id),
    })),
  );
});

app.post("/topics/:id/follow", async (c) => {
  const userId = c.get("userId");
  const topicId = c.req.param("id");
  const [topic, user] = await Promise.all([
    prisma.topic.findUnique({ where: { id: topicId } }),
    prisma.user.findUnique({ where: { id: userId }, select: { followedTopics: true } }),
  ]);
  if (!topic) return c.json({ error: "Topic not found" }, 404);
  if (user?.followedTopics.includes(topicId)) {
    return c.json({ ok: true, already: true });
  }
  await prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { followedTopics: { push: topicId } },
    }),
    prisma.topic.update({
      where: { id: topicId },
      data: { followersCount: { increment: 1 } },
    }),
  ]);
  return c.json({ ok: true });
});

app.post("/topics/:id/unfollow", async (c) => {
  const userId = c.get("userId");
  const topicId = c.req.param("id");
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { followedTopics: true },
  });
  if (!user?.followedTopics.includes(topicId)) {
    return c.json({ ok: true, already: true });
  }
  await prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { followedTopics: user.followedTopics.filter((t) => t !== topicId) },
    }),
    prisma.topic.update({
      where: { id: topicId },
      data: { followersCount: { decrement: 1 } },
    }),
  ]);
  return c.json({ ok: true });
});

// MARK: - Bootstrap

app.get("/bootstrap", async (c) => {
  const userId = c.get("userId");
  const [topics, polls, user, surveys] = await Promise.all([
    prisma.topic.findMany({ orderBy: { name: "asc" } }),
    prisma.poll.findMany({
      where: { status: "active" },
      include: {
        options: { orderBy: { displayOrder: "asc" } },
        votes: { where: { userId }, select: { userId: true, optionId: true } },
        topic: true,
        publisher: { select: { accountType: true, isVerified: true, handle: true } },
      },
      orderBy: { createdAt: "desc" },
    }),
    prisma.user.findUnique({
      where: { id: userId },
      select: { followedTopics: true },
    }),
    prisma.survey.findMany({
      where: { status: "active" },
      include: {
        questions: {
          orderBy: { displayOrder: "asc" },
          include: { options: { orderBy: { displayOrder: "asc" } } },
        },
        topic: true,
        publisher: { select: { accountType: true, isVerified: true, handle: true, name: true } },
      },
      orderBy: { createdAt: "desc" },
      take: 50,
    }),
  ]);

  const followedSet = new Set(user?.followedTopics ?? []);
  const topicsOut = topics.map((t) => ({
    ...topicDTO(t),
    is_following: followedSet.has(t.id),
  }));

  return c.json({
    topics: topicsOut,
    polls: polls.map((p) => pollDTO(p, { userId })),
    surveys: surveys.map(surveyDTO),
  });
});

// MARK: - Polls

app.get("/polls", async (c) => {
  const userId = c.get("userId");
  const status = c.req.query("status");
  const topicId = c.req.query("topic_id");
  const polls = await prisma.poll.findMany({
    where: {
      status: status === "ended" ? "ended" : status === "draft" ? "draft" : "active",
      topicId: topicId ?? undefined,
    },
    include: {
      options: { orderBy: { displayOrder: "asc" } },
      votes: { where: { userId }, select: { userId: true, optionId: true } },
      topic: true,
    },
    orderBy: { createdAt: "desc" },
    take: 100,
  });
  return c.json(polls.map((p) => pollDTO(p, { userId })));
});

app.get("/polls/:id", async (c) => {
  const userId = c.get("userId");
  const poll = await prisma.poll.findUnique({
    where: { id: c.req.param("id") },
    include: {
      options: { orderBy: { displayOrder: "asc" } },
      votes: { where: { userId }, select: { userId: true, optionId: true } },
      topic: true,
    },
  });
  if (!poll) return c.json({ error: "Poll not found" }, 404);
  return c.json(pollDTO(poll, { userId }));
});

app.post("/polls/create", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{
    poll: {
      title: string;
      description?: string;
      image_url?: string;
      cover_style?: string;
      topic_id?: string;
      topic_name?: string;
      type?: string;
      reward_points?: number;
      duration_days?: number;
      expires_at?: string;
    };
    options: Array<{ text: string }>;
  }>();

  const profile = await prisma.user.findUnique({
    where: { id: userId },
    select: { name: true, avatarInitial: true },
  });
  if (!profile) return c.json({ error: "Profile not found" }, 404);

  const durationDays = Number(body.poll.duration_days ?? 7);
  const expiresAt = body.poll.expires_at
    ? new Date(body.poll.expires_at)
    : new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000);

  const poll = await prisma.poll.create({
    data: {
      publisherId: userId,
      title: body.poll.title,
      description: body.poll.description ?? null,
      imageUrl: body.poll.image_url ?? null,
      coverStyle: body.poll.cover_style ?? null,
      authorName: profile.name,
      authorAvatar: profile.avatarInitial,
      topicId: body.poll.topic_id ?? null,
      type: (body.poll.type as any) ?? "single_choice",
      rewardPoints: body.poll.reward_points ?? 50,
      durationDays,
      expiresAt,
      options: {
        create: (body.options ?? []).map((opt, idx) => ({
          text: opt.text,
          displayOrder: idx,
        })),
      },
    },
    include: {
      options: { orderBy: { displayOrder: "asc" } },
      topic: true,
    },
  });

  return c.json({ poll: pollDTO(poll, { userId }) });
});

app.post("/polls/vote", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{
    poll_id?: string;
    pollId?: string;
    option_id?: string;
    optionId?: string;
    seconds_to_vote?: number;
  }>();
  const pollId = body.poll_id ?? body.pollId;
  const optionId = body.option_id ?? body.optionId;
  if (!pollId || !optionId) return c.json({ error: "Missing poll or option" }, 400);

  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return c.json({ error: "User not found" }, 404);

  const poll = await prisma.poll.findUnique({ where: { id: pollId } });
  if (!poll) return c.json({ error: "Poll not found" }, 404);

  const ageGroup = ageGroupFromBirthYear(user.birthYear);

  let voteCreated = false;
  try {
    await prisma.$transaction([
      prisma.vote.create({
        data: {
          pollId,
          optionId,
          userId,
          deviceType: user.deviceType,
          osVersion: user.osVersion,
          city: user.city,
          region: user.region,
          country: user.country,
          gender: user.gender,
          ageGroup,
          secondsToVote: body.seconds_to_vote ?? null,
        },
      }),
      prisma.pollOption.update({
        where: { id: optionId },
        data: { votesCount: { increment: 1 } },
      }),
      prisma.poll.update({
        where: { id: pollId },
        data: { totalVotes: { increment: 1 } },
      }),
    ]);
    voteCreated = true;
  } catch (error) {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2002"
    ) {
      return c.json({ error: "Already voted" }, 409);
    }
    throw error;
  }

  if (voteCreated) {
    const newBalance = user.points + poll.rewardPoints;
    await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: {
          points: newBalance,
          coins: newBalance / 6,
          completedPolls: user.completedPolls.includes(pollId)
            ? user.completedPolls
            : { push: pollId },
        },
      }),
      prisma.pointsLedger.create({
        data: {
          userId,
          amount: poll.rewardPoints,
          type: "vote_reward",
          refType: "poll",
          refId: pollId,
          description: `مكافأة التصويت: ${poll.title.slice(0, 60)}`,
          balanceAfter: newBalance,
        },
      }),
    ]);

    // Broadcast to dashboard subscribers (best-effort; never blocks the user).
    const newTotal = poll.totalVotes + 1;
    broadcastEvent({
      type: "vote_cast",
      pollId,
      pollTitle: poll.title,
      city: user.city,
      deviceType: user.deviceType,
      total: newTotal,
    });
    // Webhook fan-out to subscribed publishers for this poll.
    if (poll.publisherId) {
      void dispatchWebhookEvent(
        "poll.vote_cast",
        {
          poll_id: pollId,
          poll_title: poll.title,
          total: newTotal,
          city: user.city,
          device_type: user.deviceType,
          age_group: ageGroup,
          gender: user.gender,
        },
        { publisherId: poll.publisherId },
      );
    }
    if (newTotal % 100 === 0) {
      broadcastEvent({
        type: "vote_milestone",
        pollId,
        pollTitle: poll.title,
        total: newTotal,
        milestone: newTotal,
      });
      if (poll.publisherId) {
        void dispatchWebhookEvent(
          "poll.vote_milestone",
          {
            poll_id: pollId,
            poll_title: poll.title,
            total: newTotal,
            milestone: newTotal,
          },
          { publisherId: poll.publisherId },
        );
      }
    }
  }

  const fullPoll = await prisma.poll.findUnique({
    where: { id: pollId },
    include: {
      options: { orderBy: { displayOrder: "asc" } },
      votes: { where: { userId }, select: { userId: true, optionId: true } },
      topic: true,
    },
  });
  const updatedUser = await prisma.user.findUnique({ where: { id: userId } });

  // Generate AI insight (best-effort, never blocks the response if it fails)
  const insight = await aiJSON<{ insight: string }>({
    promptVersion: "poll-insight-v1",
    system:
      "Return Arabic JSON only with insight. Write one concise TRENDX poll insight.",
    input: {
      title: fullPoll?.title,
      options: fullPoll?.options.map((o) => ({
        text: o.text,
        votes: o.votesCount,
      })),
      total_votes: fullPoll?.totalVotes,
    },
    fallback: {
      insight: "النتائج بدأت تتشكل، وكل صوت جديد يضيف وضوحاً أكبر للصورة.",
    },
  });

  await prisma.poll.update({
    where: { id: pollId },
    data: { aiInsight: insight.insight },
  });
  await prisma.aIInsight.create({
    data: {
      entityId: pollId,
      entityType: "poll",
      insightType: "poll",
      modelUsed: insight.modelUsed ?? "fallback",
      promptVersion: insight.promptVersion ?? "poll-insight-v1",
      content: { insight: insight.insight },
      latencyMs: insight.latencyMs ?? null,
    },
  });

  return c.json({
    poll: pollDTO(
      { ...fullPoll!, aiInsight: insight.insight },
      { userId },
    ),
    user: userDTO(updatedUser!),
    insight: insight.insight,
  });
});

// MARK: - Surveys

app.get("/surveys", async (c) => {
  const surveys = await prisma.survey.findMany({
    where: { status: "active" },
    include: {
      questions: {
        orderBy: { displayOrder: "asc" },
        include: { options: { orderBy: { displayOrder: "asc" } } },
      },
      topic: true,
    },
    orderBy: { createdAt: "desc" },
    take: 100,
  });
  return c.json(surveys.map(surveyDTO));
});

app.get("/surveys/:id", async (c) => {
  const survey = await prisma.survey.findUnique({
    where: { id: c.req.param("id") },
    include: {
      questions: {
        orderBy: { displayOrder: "asc" },
        include: { options: { orderBy: { displayOrder: "asc" } } },
      },
      topic: true,
    },
  });
  if (!survey) return c.json({ error: "Survey not found" }, 404);
  return c.json(surveyDTO(survey));
});

app.post("/surveys/create", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{
    survey: {
      title: string;
      description?: string;
      cover_style?: string;
      topic_id?: string;
      reward_points?: number;
      duration_days?: number;
    };
    questions: Array<{
      title: string;
      type?: string;
      reward_points?: number;
      options: Array<{ text: string }>;
    }>;
  }>();

  const durationDays = Number(body.survey.duration_days ?? 14);
  const survey = await prisma.survey.create({
    data: {
      publisherId: userId,
      title: body.survey.title,
      description: body.survey.description ?? null,
      coverStyle: body.survey.cover_style ?? null,
      topicId: body.survey.topic_id ?? null,
      rewardPoints: body.survey.reward_points ?? 120,
      durationDays,
      expiresAt: new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000),
      questions: {
        create: body.questions.map((q, qIdx) => ({
          title: q.title,
          type: (q.type as any) ?? "single_choice",
          displayOrder: qIdx,
          rewardPoints: q.reward_points ?? 25,
          options: {
            create: q.options.map((o, oIdx) => ({
              text: o.text,
              displayOrder: oIdx,
            })),
          },
        })),
      },
    },
    include: {
      questions: {
        orderBy: { displayOrder: "asc" },
        include: { options: { orderBy: { displayOrder: "asc" } } },
      },
      topic: true,
    },
  });
  return c.json({ survey: surveyDTO(survey) });
});

app.post("/surveys/:id/respond", async (c) => {
  const userId = c.get("userId");
  const surveyId = c.req.param("id");
  const body = await c.req.json<{
    answers: Array<{ question_id: string; option_id: string; seconds?: number }>;
    completion_seconds?: number;
  }>();

  const [user, survey] = await Promise.all([
    prisma.user.findUnique({ where: { id: userId } }),
    prisma.survey.findUnique({
      where: { id: surveyId },
      include: { questions: true },
    }),
  ]);
  if (!user || !survey) return c.json({ error: "Not found" }, 404);

  const requiredQuestionCount = survey.questions.filter((q) => q.isRequired).length;
  const isComplete = body.answers.length >= requiredQuestionCount;
  const ageGroup = ageGroupFromBirthYear(user.birthYear);

  try {
    const response = await prisma.surveyResponse.create({
      data: {
        surveyId,
        userId,
        isComplete,
        completedAt: isComplete ? new Date() : null,
        completionSeconds: body.completion_seconds ?? null,
        deviceType: user.deviceType,
        osVersion: user.osVersion,
        city: user.city,
        region: user.region,
        country: user.country,
        gender: user.gender,
        ageGroup,
        answers: {
          create: body.answers.map((a) => ({
            questionId: a.question_id,
            optionId: a.option_id,
            secondsToAnswer: a.seconds ?? null,
          })),
        },
      },
    });

    await prisma.$transaction([
      ...body.answers.map((a) =>
        prisma.surveyQuestionOption.update({
          where: { id: a.option_id },
          data: { votesCount: { increment: 1 } },
        }),
      ),
      prisma.survey.update({
        where: { id: surveyId },
        data: {
          totalResponses: { increment: 1 },
          totalCompletes: isComplete ? { increment: 1 } : undefined,
        },
      }),
    ]);

    if (isComplete) {
      const reward = survey.rewardPoints;
      const newBalance = user.points + reward;
      await prisma.$transaction([
        prisma.user.update({
          where: { id: userId },
          data: { points: newBalance, coins: newBalance / 6 },
        }),
        prisma.pointsLedger.create({
          data: {
            userId,
            amount: reward,
            type: "survey_reward",
            refType: "survey",
            refId: surveyId,
            description: `مكافأة الاستبيان: ${survey.title.slice(0, 60)}`,
            balanceAfter: newBalance,
          },
        }),
      ]);

      const newTotal = survey.totalCompletes + 1;
      broadcastEvent({
        type: "survey_completed",
        surveyId,
        surveyTitle: survey.title,
        total: newTotal,
      });
      if (survey.publisherId) {
        void dispatchWebhookEvent(
          "survey.completed",
          {
            survey_id: surveyId,
            survey_title: survey.title,
            total_completes: newTotal,
            response_id: response.id,
          },
          { publisherId: survey.publisherId },
        );
      }
    } else if (survey.publisherId) {
      void dispatchWebhookEvent(
        "survey.response",
        {
          survey_id: surveyId,
          survey_title: survey.title,
          response_id: response.id,
          is_complete: false,
        },
        { publisherId: survey.publisherId },
      );
    }

    return c.json({ ok: true, response_id: response.id, is_complete: isComplete });
  } catch (error) {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2002"
    ) {
      return c.json({ error: "Already responded" }, 409);
    }
    throw error;
  }
});

// MARK: - Gifts

app.get("/gifts", async () => {
  const rows = await prisma.gift.findMany({
    where: { isAvailable: true },
    orderBy: { pointsRequired: "asc" },
  });

  // Compute redemption stats for social proof badges. One groupBy for the
  // last-7-days count, one findMany for the latest redemption per gift.
  const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const [weekly, latest] = await Promise.all([
    prisma.redemption.groupBy({
      by: ["giftId"],
      where: { redeemedAt: { gte: since } },
      _count: { _all: true },
    }),
    prisma.redemption.findMany({
      where: { giftId: { in: rows.map((g) => g.id) } },
      orderBy: { redeemedAt: "desc" },
      distinct: ["giftId"],
      select: { giftId: true, redeemedAt: true },
    }),
  ]);

  const weeklyByGift = new Map(weekly.map((w) => [w.giftId, w._count._all]));
  const latestByGift = new Map(latest.map((r) => [r.giftId, r.redeemedAt]));

  return Response.json(rows.map((g) => ({
    ...giftDTO(g),
    weekly_redemptions: weeklyByGift.get(g.id) ?? 0,
    last_redeemed_at: latestByGift.get(g.id)?.toISOString() ?? null,
  })));
});

app.get("/redemptions", async (c) => {
  const rows = await prisma.redemption.findMany({
    where: { userId: c.get("userId") },
    orderBy: { redeemedAt: "desc" },
  });
  return c.json(rows.map(redemptionDTO));
});

app.post("/gifts/redeem", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{ gift_id?: string; giftId?: string }>();
  const giftId = body.gift_id ?? body.giftId;
  if (!giftId) return c.json({ error: "Missing gift" }, 400);

  const [user, gift] = await Promise.all([
    prisma.user.findUnique({ where: { id: userId } }),
    prisma.gift.findUnique({ where: { id: giftId } }),
  ]);
  if (!user || !gift) return c.json({ error: "Not found" }, 404);
  if (!gift.isAvailable) return c.json({ error: "Gift not available" }, 410);
  if (user.points < gift.pointsRequired) {
    return c.json({ error: "Insufficient points" }, 402);
  }

  const code = `TX-${randomUUID().slice(0, 6).toUpperCase()}`;
  const newBalance = user.points - gift.pointsRequired;

  const [redemption, updatedUser] = await prisma.$transaction([
    prisma.redemption.create({
      data: {
        userId,
        giftId,
        giftName: gift.name,
        brandName: gift.brandName,
        pointsSpent: gift.pointsRequired,
        valueInRiyal: gift.valueInRiyal,
        code,
      },
    }),
    prisma.user.update({
      where: { id: userId },
      data: { points: newBalance, coins: newBalance / 6 },
    }),
    prisma.pointsLedger.create({
      data: {
        userId,
        amount: -gift.pointsRequired,
        type: "redemption",
        refType: "redemption",
        refId: giftId,
        description: `استبدال هدية: ${gift.name}`,
        balanceAfter: newBalance,
      },
    }),
  ]);

  broadcastEvent({
    type: "gift_redeemed",
    giftId,
    giftName: gift.name,
    brandName: gift.brandName,
    pointsSpent: gift.pointsRequired,
    valueInRiyal: Number(gift.valueInRiyal),
  });

  return c.json({
    redemption: redemptionDTO(redemption),
    user: userDTO(updatedUser),
  });
});

// MARK: - Points ledger

app.get("/points/ledger", async (c) => {
  const rows = await prisma.pointsLedger.findMany({
    where: { userId: c.get("userId") },
    orderBy: { createdAt: "desc" },
    take: 100,
  });
  return c.json(snake(rows));
});

// MARK: - AI

app.post("/ai/compose-poll", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{
    question?: string;
    topic_name?: string;
    type?: string;
  }>();
  const fallback = {
    question: body.question ?? "",
    options: ["أوافق", "محايد", "لا أوافق"],
    clarityScore: 70,
    rationale: "اقتراح احتياطي جاهز للـ Beta.",
  };
  const result = await aiJSON({
    promptVersion: "compose-poll-v1",
    system:
      "Return Arabic JSON only with question, options, clarityScore, rationale.",
    input: body,
    fallback,
  });
  await prisma.aIInsight.create({
    data: {
      entityId: userId,
      entityType: "user",
      insightType: "auto_tag",
      modelUsed: result.modelUsed ?? "fallback",
      promptVersion: result.promptVersion ?? "compose-poll-v1",
      content: result as Prisma.InputJsonValue,
      latencyMs: result.latencyMs ?? null,
    },
  });
  return c.json(result);
});

app.post("/ai/poll-insight", async (c) => {
  const body = await c.req.json<{ poll?: { title?: string; options?: unknown } }>();
  const result = await aiJSON({
    promptVersion: "poll-insight-v1",
    system:
      "Return Arabic JSON only with insight. Write one concise TRENDX poll insight.",
    input: body,
    fallback: {
      insight: "النتائج بدأت تتشكل، وكل صوت جديد يضيف وضوحاً أكبر للصورة.",
    },
  });
  return c.json(result);
});

// MARK: - AI reports

type SurveyReportShape = {
  executive_summary: string;
  key_findings: Array<{ finding: string; supporting_stat: string }>;
  persona_profiles: Array<{
    name: string;
    traits: string[];
    percent: number;
    representative_quote: string;
  }>;
  hidden_patterns: Array<{
    pattern: string;
    probability_pct: number;
    implication: string;
  }>;
  strategic_recommendations: string[];
  sector_position: string;
};

type SectorReportShape = {
  sector_sentiment_score: number;
  sentiment_direction: "rising" | "falling" | "stable";
  consensus_map: Array<{ question: string; leading_pct: number; label: string }>;
  sector_persona: { name: string; description: string; share_pct: number };
  cross_survey_patterns: string[];
  strategic_brief: string;
  predicted_trend: string;
};

const SURVEY_REPORT_FALLBACK: SurveyReportShape = {
  executive_summary:
    "هذا تقرير احتياطي يُعرض حين لا يتوفّر مفتاح OpenAI. سيظهر التقرير الكامل من GPT-4o فور تكوين المتغيّر OPENAI_API_KEY في Railway. البيانات الإحصائية الأساسية (الإكمال، الديموغرافيا، الإجماع) متاحة في تبويب الملخّص.",
  key_findings: [
    { finding: "حجم العيّنة كافٍ لاستنتاجات أوّلية", supporting_stat: "مرجع: completion_rate" },
    { finding: "تنوع جغرافي حاضر في الاستجابات", supporting_stat: "مرجع: by_city_top" },
  ],
  persona_profiles: [],
  hidden_patterns: [],
  strategic_recommendations: [
    "اربط مفتاح OpenAI لتفعيل تحليل الشخصيات والأنماط الخفية",
  ],
  sector_position: "بانتظار AI لإصدار قراءة قطاعية مقارنة.",
};

const SECTOR_REPORT_FALLBACK: SectorReportShape = {
  sector_sentiment_score: 60,
  sentiment_direction: "stable",
  consensus_map: [],
  sector_persona: { name: "غير متوفّر", description: "بانتظار تفعيل AI", share_pct: 0 },
  cross_survey_patterns: [],
  strategic_brief: "تقرير احتياطي. اربط OpenAI لإصدار البريف الكامل.",
  predicted_trend: "بانتظار التحليل التنبّؤي",
};

app.get("/surveys/:id/analytics/ai-report", async (c) => {
  const surveyId = c.req.param("id");
  const cached = await prisma.aIInsight.findFirst({
    where: { entityId: surveyId, entityType: "survey", insightType: "survey" },
    orderBy: { generatedAt: "desc" },
  });
  // Cache for 6 hours
  if (cached && Date.now() - cached.generatedAt.getTime() < 6 * 60 * 60 * 1000) {
    return c.json({
      cached: true,
      generated_at: cached.generatedAt.toISOString(),
      prompt_version: cached.promptVersion,
      model: cached.modelUsed,
      report: cached.content,
    });
  }

  const analytics = await getCachedOrComputeSurvey(surveyId);
  const survey = await prisma.survey.findUnique({
    where: { id: surveyId },
    include: {
      questions: {
        orderBy: { displayOrder: "asc" },
        include: { options: { orderBy: { displayOrder: "asc" } } },
      },
    },
  });
  if (!survey || !analytics) return c.json({ error: "Survey not found" }, 404);

  const report = await aiJSON<SurveyReportShape>({
    promptVersion: PROMPT_VERSIONS.surveyReport,
    system: SYSTEM_PROMPTS.surveyReport,
    fallback: SURVEY_REPORT_FALLBACK,
    input: {
      title: survey.title,
      description: survey.description,
      sample_size: analytics.sample_size,
      completion_rate: analytics.completion_rate,
      breakdown: analytics.breakdown,
      per_question: analytics.per_question,
      correlations: analytics.correlations,
    },
  });

  const insight = await prisma.aIInsight.create({
    data: {
      entityId: surveyId,
      entityType: "survey",
      insightType: "survey",
      modelUsed: report.modelUsed ?? "fallback",
      promptVersion: report.promptVersion ?? PROMPT_VERSIONS.surveyReport,
      content: report as Prisma.InputJsonValue,
      latencyMs: report.latencyMs ?? null,
    },
  });

  return c.json({
    cached: false,
    generated_at: insight.generatedAt.toISOString(),
    prompt_version: insight.promptVersion,
    model: insight.modelUsed,
    report,
  });
});

app.get("/topics/:id/insight", async (c) => {
  const topicId = c.req.param("id");
  const cached = await prisma.aIInsight.findFirst({
    where: { entityId: topicId, entityType: "topic", insightType: "sector" },
    orderBy: { generatedAt: "desc" },
  });
  if (cached && Date.now() - cached.generatedAt.getTime() < 6 * 60 * 60 * 1000) {
    return c.json({
      cached: true,
      generated_at: cached.generatedAt.toISOString(),
      prompt_version: cached.promptVersion,
      model: cached.modelUsed,
      report: cached.content,
    });
  }

  const topic = await prisma.topic.findUnique({ where: { id: topicId } });
  if (!topic) return c.json({ error: "Topic not found" }, 404);

  const [polls, surveys] = await Promise.all([
    prisma.poll.findMany({
      where: { topicId, status: "active" },
      include: { options: true },
    }),
    prisma.survey.findMany({
      where: { topicId, status: "active" },
      include: {
        questions: {
          orderBy: { displayOrder: "asc" },
          include: { options: true },
        },
      },
    }),
  ]);

  const totalVotes = polls.reduce((acc, p) => acc + p.totalVotes, 0);
  const totalResponses = surveys.reduce((acc, s) => acc + s.totalResponses, 0);

  const report = await aiJSON<SectorReportShape>({
    promptVersion: PROMPT_VERSIONS.sectorReport,
    system: SYSTEM_PROMPTS.sectorReport,
    fallback: SECTOR_REPORT_FALLBACK,
    input: {
      topic: topic.name,
      polls_count: polls.length,
      surveys_count: surveys.length,
      total_votes: totalVotes,
      total_responses: totalResponses,
      polls_summary: polls.map((p) => ({
        title: p.title,
        total_votes: p.totalVotes,
        leading_option: p.options
          .slice()
          .sort((a, b) => b.votesCount - a.votesCount)[0]?.text,
      })),
      surveys_summary: surveys.map((s) => ({
        title: s.title,
        total: s.totalResponses,
        completion_rate: s.totalResponses > 0
          ? Math.round((s.totalCompletes / s.totalResponses) * 100)
          : 0,
      })),
    },
  });

  const insight = await prisma.aIInsight.create({
    data: {
      entityId: topicId,
      entityType: "topic",
      insightType: "sector",
      modelUsed: report.modelUsed ?? "fallback",
      promptVersion: report.promptVersion ?? PROMPT_VERSIONS.sectorReport,
      content: report as Prisma.InputJsonValue,
      latencyMs: report.latencyMs ?? null,
    },
  });

  return c.json({
    cached: false,
    generated_at: insight.generatedAt.toISOString(),
    prompt_version: insight.promptVersion,
    model: insight.modelUsed,
    polls_count: polls.length,
    surveys_count: surveys.length,
    total_votes: totalVotes,
    total_responses: totalResponses,
    report,
  });
});

app.post("/ai/question-quality", async (c) => {
  const body = await c.req.json<{ title?: string; options?: string[] }>();
  const result = await aiJSON({
    promptVersion: PROMPT_VERSIONS.questionQuality,
    system: SYSTEM_PROMPTS.questionQuality,
    input: { title: body.title, options: body.options ?? [] },
    fallback: {
      clarity_score: 70,
      leading_bias: 30,
      predicted_engagement: "medium",
      issues: [],
      suggestions: [],
      rewrite: body.title ?? "",
    },
  });
  return c.json(result);
});

// MARK: - Analytics

app.get("/analytics/poll/:id", async (c) => {
  const payload = await getCachedOrComputePoll(c.req.param("id"));
  if (!payload) return c.json({ error: "Poll not found" }, 404);
  return c.json(payload);
});

app.get("/analytics/survey/:id", async (c) => {
  const payload = await getCachedOrComputeSurvey(c.req.param("id"));
  if (!payload) return c.json({ error: "Survey not found" }, 404);
  return c.json(payload);
});

app.post("/admin/snapshots/run", async (c) => {
  await runSnapshotsNow();
  return c.json({ ok: true, ranAt: new Date().toISOString() });
});

// MARK: - Layer 3 — Deep Analytics
//
// All endpoints here are read-only, on-demand. They share the same JSON
// contract surface that iOS will consume when we add a publisher-mode
// view to the iPhone app, so the keys are snake_case and never change
// shape based on caller.

const HEATMAP_DIMS = new Set<HeatmapDimension>(["gender", "age_group", "city", "device"]);

function parseDim(value: string | undefined, fallback: HeatmapDimension): HeatmapDimension {
  if (value && HEATMAP_DIMS.has(value as HeatmapDimension)) return value as HeatmapDimension;
  return fallback;
}

app.get("/analytics/poll/:id/heatmap", async (c) => {
  const pollId = c.req.param("id");
  const x = parseDim(c.req.query("x"), "gender");
  const y = parseDim(c.req.query("y"), "age_group");
  const optionId = c.req.query("option_id");
  const payload = await computePollHeatmap(pollId, x, y, optionId);
  if (!payload) return c.json({ error: "Poll not found" }, 404);
  return c.json(payload);
});

app.get("/analytics/survey/:id/heatmap", async (c) => {
  const surveyId = c.req.param("id");
  const x = parseDim(c.req.query("x"), "gender");
  const y = parseDim(c.req.query("y"), "age_group");
  const questionId = c.req.query("question_id");
  const optionId = c.req.query("option_id");
  const payload = await computeSurveyHeatmap(surveyId, x, y, questionId, optionId);
  if (!payload) return c.json({ error: "Survey not found" }, 404);
  return c.json(payload);
});

app.get("/analytics/survey/:id/cross-question", async (c) => {
  const surveyId = c.req.param("id");
  const q1 = c.req.query("q1");
  const q2 = c.req.query("q2");
  if (!q1 || !q2) return c.json({ error: "q1 and q2 query params required" }, 400);
  const payload = await computeCrossQuestion(surveyId, q1, q2);
  if (!payload) return c.json({ error: "Questions not found" }, 404);
  return c.json(payload);
});

app.get("/analytics/topic/:id/sentiment-timeline", async (c) => {
  const topicId = c.req.param("id");
  const days = Math.max(7, Math.min(90, Number(c.req.query("days") ?? 30)));
  const payload = await getCachedSentimentTimeline(topicId, days);
  if (!payload) return c.json({ error: "Topic not found" }, 404);
  return c.json(payload);
});

app.get("/analytics/sectors/benchmark", async (c) => {
  const ids = (c.req.query("topic_ids") ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (ids.length === 0) return c.json({ error: "topic_ids query required" }, 400);
  if (ids.length > 6) return c.json({ error: "Maximum 6 sectors per benchmark" }, 400);
  const payload = await getCachedSectorBenchmark(ids);
  return c.json(payload);
});

// MARK: - Personas

app.get("/surveys/:id/personas", async (c) => {
  const surveyId = c.req.param("id");
  const force = c.req.query("refresh") === "1";
  const payload = await computeSurveyPersonas(surveyId, force);
  if (!payload) return c.json({ error: "Survey not found" }, 404);
  return c.json(payload);
});

// MARK: - Webhooks (Publisher API)

app.get("/publisher/webhooks", async (c) => {
  const userId = c.get("userId");
  const rows = await prisma.webhook.findMany({
    where: { publisherId: userId },
    orderBy: { createdAt: "desc" },
  });
  return c.json(snake(rows));
});

app.post("/publisher/webhooks", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{
    url?: string;
    events?: string[];
  }>();
  const url = (body.url ?? "").trim();
  const events = (body.events ?? []).filter((e) => typeof e === "string" && e.length > 0);
  if (!url.startsWith("https://") || events.length === 0) {
    return c.json({ error: "url (https://) and at least one event required" }, 400);
  }
  const wh = await prisma.webhook.create({
    data: {
      publisherId: userId,
      url,
      events,
      secret: generateWebhookSecret(),
    },
  });
  return c.json(snake(wh));
});

app.patch("/publisher/webhooks/:id", async (c) => {
  const userId = c.get("userId");
  const id = c.req.param("id");
  const existing = await prisma.webhook.findUnique({ where: { id } });
  if (!existing || existing.publisherId !== userId) {
    return c.json({ error: "Webhook not found" }, 404);
  }
  const body = await c.req.json<{ url?: string; events?: string[]; is_active?: boolean }>();
  const wh = await prisma.webhook.update({
    where: { id },
    data: {
      ...(body.url !== undefined ? { url: body.url } : {}),
      ...(body.events !== undefined ? { events: body.events } : {}),
      ...(body.is_active !== undefined ? { isActive: body.is_active } : {}),
    },
  });
  return c.json(snake(wh));
});

app.delete("/publisher/webhooks/:id", async (c) => {
  const userId = c.get("userId");
  const id = c.req.param("id");
  const existing = await prisma.webhook.findUnique({ where: { id } });
  if (!existing || existing.publisherId !== userId) {
    return c.json({ error: "Webhook not found" }, 404);
  }
  await prisma.webhook.delete({ where: { id } });
  return c.json({ ok: true });
});

app.post("/publisher/webhooks/:id/test", async (c) => {
  const userId = c.get("userId");
  const id = c.req.param("id");
  const existing = await prisma.webhook.findUnique({ where: { id } });
  if (!existing || existing.publisherId !== userId) {
    return c.json({ error: "Webhook not found" }, 404);
  }
  const result = await testWebhook(id);
  return c.json(result);
});

// MARK: - Admin Console

app.get("/admin/users", async (c) => {
  const actor = await loadActor(c);
  if (!actor || actor.role !== "admin") return c.json({ error: "Forbidden" }, 403);
  const q = (c.req.query("q") ?? "").trim();
  const role = c.req.query("role");
  const tier = c.req.query("tier");
  const limit = Math.min(200, Number(c.req.query("limit") ?? 50));
  const users = await prisma.user.findMany({
    where: {
      AND: [
        q ? {
          OR: [
            { email: { contains: q, mode: "insensitive" } },
            { name:  { contains: q, mode: "insensitive" } },
          ],
        } : {},
        role ? { role: role as "respondent" | "publisher" | "admin" } : {},
        tier ? { tier: tier as "free" | "premium" | "enterprise" } : {},
      ],
    },
    orderBy: { lastActiveAt: "desc" },
    take: limit,
    select: {
      id: true, email: true, name: true, role: true, tier: true,
      city: true, country: true, gender: true, deviceType: true,
      points: true, isPremium: true,
      joinedAt: true, lastActiveAt: true,
    },
  });
  return c.json(snake(users));
});

app.patch("/admin/users/:id", async (c) => {
  const actor = await loadActor(c);
  if (!actor || actor.role !== "admin") return c.json({ error: "Forbidden" }, 403);
  const targetId = c.req.param("id");
  const body = await c.req.json<{
    role?: "respondent" | "publisher" | "admin";
    tier?: "free" | "premium" | "enterprise";
    is_premium?: boolean;
  }>();
  const user = await prisma.user.update({
    where: { id: targetId },
    data: {
      ...(body.role ? { role: body.role } : {}),
      ...(body.tier ? { tier: body.tier } : {}),
      ...(body.is_premium !== undefined ? { isPremium: body.is_premium } : {}),
    },
  });
  await prisma.auditLog.create({
    data: {
      actorId: actor.id,
      action: "user.updated",
      resourceType: "user",
      resourceId: targetId,
      metadata: body as unknown as Prisma.InputJsonValue,
    },
  });
  return c.json(userDTO(user));
});

app.get("/admin/audit-log", async (c) => {
  const actor = await loadActor(c);
  if (!actor || actor.role !== "admin") return c.json({ error: "Forbidden" }, 403);
  const limit = Math.min(500, Number(c.req.query("limit") ?? 100));
  const rows = await prisma.auditLog.findMany({
    orderBy: { createdAt: "desc" },
    take: limit,
  });
  return c.json(snake(rows));
});

app.get("/admin/jobs/status", async (c) => {
  const actor = await loadActor(c);
  if (!actor || actor.role !== "admin") return c.json({ error: "Forbidden" }, 403);
  const [latestSnapshot, latestInsight, webhooksTotal, webhooksActive, recentDeliveries] =
    await Promise.all([
      prisma.analyticsSnapshot.findFirst({ orderBy: { computedAt: "desc" } }),
      prisma.aIInsight.findFirst({ orderBy: { generatedAt: "desc" } }),
      prisma.webhook.count(),
      prisma.webhook.count({ where: { isActive: true } }),
      prisma.auditLog.findMany({
        where: { resourceType: "webhook" },
        orderBy: { createdAt: "desc" },
        take: 20,
      }),
    ]);
  return c.json({
    snapshot: latestSnapshot ? {
      computed_at: latestSnapshot.computedAt.toISOString(),
      entity_type: latestSnapshot.entityType,
      entity_id: latestSnapshot.entityId,
    } : null,
    last_ai_insight: latestInsight ? {
      generated_at: latestInsight.generatedAt.toISOString(),
      insight_type: latestInsight.insightType,
      model: latestInsight.modelUsed,
      latency_ms: latestInsight.latencyMs,
    } : null,
    webhooks: { total: webhooksTotal, active: webhooksActive },
    recent_webhook_deliveries: snake(recentDeliveries),
    server_time: new Date().toISOString(),
  });
});

app.get("/admin/sectors", async (c) => {
  const actor = await loadActor(c);
  if (!actor || actor.role !== "admin") return c.json({ error: "Forbidden" }, 403);
  const rows = await prisma.topic.findMany({
    orderBy: { name: "asc" },
    include: { _count: { select: { polls: true, surveys: true } } },
  });
  return c.json(snake(rows));
});

app.post("/admin/sectors", async (c) => {
  const actor = await loadActor(c);
  if (!actor || actor.role !== "admin") return c.json({ error: "Forbidden" }, 403);
  const body = await c.req.json<{
    name?: string; slug?: string; icon?: string; color?: string; parent_id?: string | null;
  }>();
  if (!body.name || !body.slug || !body.icon) {
    return c.json({ error: "name, slug, icon required" }, 400);
  }
  const topic = await prisma.topic.create({
    data: {
      name: body.name,
      slug: body.slug,
      icon: body.icon,
      color: body.color ?? "blue",
      parentId: body.parent_id ?? null,
    },
  });
  await prisma.auditLog.create({
    data: {
      actorId: actor.id,
      action: "sector.created",
      resourceType: "topic",
      resourceId: topic.id,
      metadata: body as unknown as Prisma.InputJsonValue,
    },
  });
  return c.json(topicDTO(topic));
});

app.patch("/admin/sectors/:id", async (c) => {
  const actor = await loadActor(c);
  if (!actor || actor.role !== "admin") return c.json({ error: "Forbidden" }, 403);
  const id = c.req.param("id");
  const body = await c.req.json<{
    name?: string; slug?: string; icon?: string; color?: string;
  }>();
  const topic = await prisma.topic.update({
    where: { id },
    data: {
      ...(body.name ? { name: body.name } : {}),
      ...(body.slug ? { slug: body.slug } : {}),
      ...(body.icon ? { icon: body.icon } : {}),
      ...(body.color ? { color: body.color } : {}),
    },
  });
  await prisma.auditLog.create({
    data: {
      actorId: actor.id,
      action: "sector.updated",
      resourceType: "topic",
      resourceId: id,
      metadata: body as unknown as Prisma.InputJsonValue,
    },
  });
  return c.json(topicDTO(topic));
});

// MARK: - Daily Pulse (نبض اليوم)
//
// One national question per day, surfaced on iOS home and the dashboard
// overview. The same JSON shape is consumed by both — the platform is
// one product, the surfaces are different.

app.get("/pulse/today", async (c) => {
  const userId = c.get("userId");
  const payload = await getCurrentPulseForUser(userId);
  return c.json(payload);
});

app.get("/pulse/today/anon", async (_c) => {
  // Embeddable / preview shape — no user_responded flag.
  const payload = await getOrCreateTodayPulse();
  return _c.json(payload);
});

app.post("/pulse/today/respond", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{ option_index?: number; predicted_pct?: number }>();
  if (typeof body.option_index !== "number") {
    return c.json({ error: "option_index is required" }, 400);
  }
  try {
    const result = await recordPulseResponse(userId, body.option_index, body.predicted_pct);
    broadcastEvent({
      type: "pulse_response",
      pulse_id: result.pulse.id,
      total: result.pulse.total_responses,
      timestamp: new Date().toISOString(),
    });
    return c.json(result);
  } catch (err) {
    const status = (err as { httpStatus?: number }).httpStatus ?? 400;
    return c.json({ error: (err as Error).message }, status as 400 | 409);
  }
});

app.get("/pulse/yesterday", async (c) => {
  const previous = await previousPulseSummary();
  return c.json({ pulse: previous });
});

app.get("/pulse/history", async (c) => {
  const days = Math.min(60, Math.max(1, Number(c.req.query("days") ?? "14")));
  const items = await pulseHistory(days);
  return c.json({ items });
});

app.get("/me/streak", async (c) => {
  const userId = c.get("userId");
  const streak = await getStreak(userId);
  return c.json(streak);
});

// MARK: - Smart notifications

app.get("/me/notifications", async (c) => {
  const userId = c.get("userId");
  const items = await buildNotifications(userId);
  return c.json({ items });
});

// MARK: - Daily bonus
//
// Awards a small streak-amplifying bonus once per calendar day. State is
// tracked entirely through the existing `points_ledger` table — we look
// for a `daily_bonus` entry in the last 24 hours to decide whether the
// user is eligible. Reward grows with the streak of consecutive daily
// claims (capped at 7).

app.get("/me/daily-bonus", async (c) => {
  const userId = c.get("userId");
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000);

  const recent = await prisma.pointsLedger.findFirst({
    where: { userId, type: "daily_bonus", createdAt: { gte: since } },
    orderBy: { createdAt: "desc" },
  });
  const streak = await dailyBonusStreak(userId);
  const nextReward = dailyBonusAmount(streak + (recent ? 0 : 1));

  return c.json({
    can_claim: recent === null,
    current_streak: streak,
    next_reward: nextReward,
    last_claimed_at: recent?.createdAt.toISOString() ?? null,
  });
});

app.post("/me/daily-bonus/claim", async (c) => {
  const userId = c.get("userId");
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000);

  const recent = await prisma.pointsLedger.findFirst({
    where: { userId, type: "daily_bonus", createdAt: { gte: since } },
  });
  if (recent) {
    return c.json({ error: "Already claimed today" }, 409);
  }

  const streak = (await dailyBonusStreak(userId)) + 1;
  const amount = dailyBonusAmount(streak);

  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return c.json({ error: "User not found" }, 404);

  const newBalance = user.points + amount;
  const [, updatedUser] = await prisma.$transaction([
    prisma.pointsLedger.create({
      data: {
        userId,
        amount,
        type: "daily_bonus",
        refType: "daily_bonus",
        refId: null,
        description: `مكافأة الدخول اليومي · يوم ${streak}`,
        balanceAfter: newBalance,
      },
    }),
    prisma.user.update({
      where: { id: userId },
      data: { points: newBalance, coins: newBalance / 6 },
    }),
  ]);

  return c.json({
    awarded: amount,
    new_streak: streak,
    user: userDTO(updatedUser),
  });
});

async function dailyBonusStreak(userId: string): Promise<number> {
  // Count consecutive days (back-to-back, including today) the user has
  // claimed the bonus. We look at the latest 14 entries and walk back.
  const recent = await prisma.pointsLedger.findMany({
    where: { userId, type: "daily_bonus" },
    orderBy: { createdAt: "desc" },
    take: 14,
  });
  if (recent.length === 0) return 0;

  let streak = 1;
  const dayKey = (d: Date) => d.toISOString().slice(0, 10);
  let prevDay = dayKey(recent[0].createdAt);

  for (let i = 1; i < recent.length; i += 1) {
    const day = dayKey(recent[i].createdAt);
    const expectedPrev = new Date(prevDay);
    expectedPrev.setUTCDate(expectedPrev.getUTCDate() - 1);
    if (day !== dayKey(expectedPrev)) break;
    streak += 1;
    prevDay = day;
  }
  return streak;
}

function dailyBonusAmount(streakDay: number): number {
  // Day 1 → 5 pts, day 2 → 8, day 3 → 12, day 4 → 18, day 5 → 25,
  // day 6 → 35, day 7+ → 50 (caps).
  const table = [5, 8, 12, 18, 25, 35, 50];
  const idx = Math.max(1, Math.min(streakDay, table.length)) - 1;
  return table[idx];
}

// MARK: - Publisher audience stats
//
// One endpoint that powers the "Reach + Demographics" story for the
// publisher dashboard. Everything is aggregated live — no caching —
// because the values move slowly enough that recomputing per request
// (~6 indexed queries) is still cheap, and freshness matters here.
//
// The endpoint is intentionally public so the marketing/business page
// can render the totals before sign-in. We only return aggregates, no
// individual user data.

app.get("/public/audience-stats", async () => {
  const now = new Date();
  const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

  const [
    totalUsers,
    activeWeek,
    activeMonth,
    votesToday,
    votesWeek,
    redemptionsWeek,
    pollsActive,
    surveysActive,
    genderRows,
    ageRows,
    cityRows,
    deviceRows,
    topicCountRows,
  ] = await Promise.all([
    prisma.user.count(),
    prisma.user.count({ where: { lastActiveAt: { gte: weekAgo } } }),
    prisma.user.count({ where: { lastActiveAt: { gte: monthAgo } } }),
    prisma.vote.count({ where: { votedAt: { gte: dayAgo } } }),
    prisma.vote.count({ where: { votedAt: { gte: weekAgo } } }),
    prisma.redemption.count({ where: { redeemedAt: { gte: weekAgo } } }),
    prisma.poll.count({ where: { status: "active" } }),
    prisma.survey.count({ where: { status: "active" } }),
    prisma.user.groupBy({ by: ["gender"], _count: { _all: true } }),
    // Vote table denormalizes age_group per response, so it's the cleanest
    // source for an "audience demographics" aggregation.
    prisma.vote.groupBy({
      by: ["ageGroup"],
      _count: { _all: true },
      where: { ageGroup: { not: null } },
    }),
    prisma.user.groupBy({
      by: ["city"],
      _count: { _all: true },
      where: { city: { not: null } },
      orderBy: { _count: { id: "desc" } },
      take: 6,
    }),
    prisma.user.groupBy({ by: ["deviceType"], _count: { _all: true } }),
    prisma.poll.groupBy({
      by: ["topicId"],
      _count: { _all: true },
      where: { status: "active", topicId: { not: null } },
      orderBy: { _count: { id: "desc" } },
      take: 5,
    }),
  ]);

  const topicIds = topicCountRows
    .map((r) => r.topicId)
    .filter((id): id is string => typeof id === "string");
  const topics = topicIds.length
    ? await prisma.topic.findMany({
        where: { id: { in: topicIds } },
        select: { id: true, name: true, icon: true },
      })
    : [];
  const topicById = new Map(topics.map((t) => [t.id, t]));

  const pct = (count: number, denominator: number) =>
    denominator > 0 ? Math.round((count / denominator) * 1000) / 10 : 0;

  return Response.json({
    headline: {
      total_users: totalUsers,
      active_last_week: activeWeek,
      active_last_month: activeMonth,
      votes_today: votesToday,
      votes_last_week: votesWeek,
      redemptions_last_week: redemptionsWeek,
      polls_active: pollsActive,
      surveys_active: surveysActive,
    },
    gender: genderRows.map((r) => ({
      key: r.gender,
      count: r._count._all,
      percentage: pct(r._count._all, totalUsers),
    })),
    age: ageRows.map((r) => ({
      key: r.ageGroup ?? "غير محدد",
      count: r._count._all,
      percentage: pct(r._count._all, totalUsers),
    })),
    cities: cityRows.map((r) => ({
      key: r.city ?? "غير محدد",
      count: r._count._all,
      percentage: pct(r._count._all, totalUsers),
    })),
    device: deviceRows.map((r) => ({
      key: r.deviceType,
      count: r._count._all,
      percentage: pct(r._count._all, totalUsers),
    })),
    top_topics: topicCountRows.map((r) => ({
      topic_id: r.topicId,
      name: topicById.get(r.topicId ?? "")?.name ?? "—",
      icon: topicById.get(r.topicId ?? "")?.icon ?? "tag",
      polls_count: r._count._all,
    })),
    generated_at: now.toISOString(),
  });
});

// MARK: - Opinion DNA

app.get("/me/dna", async (c) => {
  const userId = c.get("userId");
  const dna = await getCachedOpinionDNA(userId);
  if (!dna) {
    return c.json({ error: "Not enough vote history yet — vote on at least 3 polls." }, 422);
  }
  return c.json(dna);
});

app.post("/me/dna/refresh", async (c) => {
  const userId = c.get("userId");
  const dna = await getCachedOpinionDNA(userId, true);
  if (!dna) return c.json({ error: "Not enough history" }, 422);
  return c.json(dna);
});

// MARK: - Audience Marketplace

app.post("/publisher/audiences/estimate", async (c) => {
  const userId = c.get("userId");
  const me = await prisma.user.findUnique({ where: { id: userId }, select: { tier: true } });
  const body = await c.req.json<{ criteria?: AudienceCriteria }>();
  if (!body.criteria) return c.json({ error: "criteria is required" }, 400);
  const est = await estimateAudience(body.criteria, me?.tier ?? "free");
  return c.json(est);
});

app.get("/publisher/audiences", async (c) => {
  const userId = c.get("userId");
  const list = await listPublisherAudiences(userId);
  return c.json({
    items: list.map((a) => ({
      id: a.id,
      name: a.name,
      criteria: a.criteria,
      available_count: a.availableCount,
      estimated_price_sar: Number(a.estimatedPrice),
      status: a.status,
      poll_id: a.pollId,
      survey_id: a.surveyId,
      created_at: a.createdAt.toISOString(),
    })),
  });
});

app.post("/publisher/audiences", async (c) => {
  const userId = c.get("userId");
  const me = await prisma.user.findUnique({ where: { id: userId }, select: { tier: true } });
  const body = await c.req.json<{ name?: string; criteria?: AudienceCriteria }>();
  if (!body.name || !body.criteria) {
    return c.json({ error: "name and criteria are required" }, 400);
  }
  const created = await createAudience(userId, {
    name: body.name,
    criteria: body.criteria,
    publisherTier: me?.tier ?? "free",
  });
  return c.json({
    id: created.id,
    name: created.name,
    available_count: created.availableCount,
    estimated_price_sar: Number(created.estimatedPrice),
    status: created.status,
    created_at: created.createdAt.toISOString(),
  });
});

// MARK: - TRENDX Index (public)

app.get("/public/index", async (c) => {
  const idx = await getCachedTrendXIndex();
  return c.json(idx);
});

app.get("/public/index/refresh", async (c) => {
  // Admin-only refresh; gated by header secret to keep cron simple.
  const secret = c.req.header("X-Trendx-Cron");
  if (secret !== process.env.CRON_SECRET) return c.json({ error: "unauthorized" }, 401);
  const fresh = await getCachedTrendXIndex(true);
  return c.json(fresh);
});

// MARK: - Embeddable Widget (poll preview)
//
// Renders a tiny self-contained HTML page that any publisher can iframe
// into their own news site or blog. The widget loads its data from the
// same JSON endpoint our app uses — no extra surface area.

app.get("/embed/poll/:id", async (c) => {
  const id = c.req.param("id");
  const poll = await prisma.poll.findUnique({
    where: { id },
    include: {
      options: { orderBy: { displayOrder: "asc" } },
    },
  });
  if (!poll) {
    return c.text("<!doctype html><body>poll not found</body>", 404, { "Content-Type": "text/html; charset=utf-8" });
  }
  const total = poll.totalVotes || 1;
  const optionsHtml = poll.options
    .map((o) => {
      const pct = total > 0 ? Math.round((o.votesCount / total) * 100) : 0;
      return `
        <div class="row">
          <div class="head"><span>${escapeHtml(o.text)}</span><b>${pct}%</b></div>
          <div class="bar"><div class="fill" style="width:${pct}%"></div></div>
        </div>`;
    })
    .join("");

  const html = `<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${escapeHtml(poll.title)} — TRENDX</title>
<style>
  :root { color-scheme: light; }
  body{font-family:-apple-system,Tajawal,Inter,system-ui,sans-serif;background:#F4F5FA;color:#1A1B25;margin:0;padding:20px;}
  .card{background:#fff;border-radius:20px;padding:22px;box-shadow:0 4px 16px rgba(59,91,219,.08);max-width:520px;margin:0 auto;}
  .eyebrow{font-size:10px;letter-spacing:.16em;color:#3B5BDB;font-weight:700;text-transform:uppercase;}
  h1{font-size:18px;line-height:1.4;margin:8px 0 16px;font-weight:700;}
  .row{margin-bottom:14px;}
  .head{display:flex;justify-content:space-between;font-size:13px;font-weight:600;margin-bottom:6px;}
  .bar{height:8px;background:#E4E7F5;border-radius:999px;overflow:hidden;}
  .fill{height:100%;background:linear-gradient(90deg,#3B5BDB,#4C6EF5);border-radius:999px;transition:width .6s ease;}
  .footer{margin-top:18px;display:flex;justify-content:space-between;align-items:center;font-size:11px;color:#868E96;}
  a{color:#3B5BDB;text-decoration:none;font-weight:700;}
</style>
</head>
<body>
<div class="card">
  <div class="eyebrow">TRENDX POLL</div>
  <h1>${escapeHtml(poll.title)}</h1>
  ${optionsHtml}
  <div class="footer">
    <span>${total.toLocaleString("en-US")} مشارك</span>
    <a href="https://t-rend-x.vercel.app/polls/${poll.id}" target="_blank">شاهد التحليل الكامل ←</a>
  </div>
</div>
</body>
</html>`;
  return c.text(html, 200, {
    "Content-Type": "text/html; charset=utf-8",
    "X-Frame-Options": "ALLOWALL",
    "Cache-Control": "public, max-age=60",
  });
});

app.get("/widget.js", (c) => {
  const js = `(function(){
  var hosts = document.querySelectorAll('[data-trendx-poll]');
  hosts.forEach(function(el){
    var id = el.getAttribute('data-trendx-poll');
    if(!id) return;
    var iframe = document.createElement('iframe');
    iframe.src = 'https://trendx-production.up.railway.app/embed/poll/' + id;
    iframe.style.cssText = 'border:0;width:100%;max-width:560px;height:420px;display:block;margin:0 auto;';
    iframe.loading = 'lazy';
    iframe.title = 'TRENDX Poll';
    el.innerHTML = '';
    el.appendChild(iframe);
  });
})();`;
  return c.text(js, 200, {
    "Content-Type": "application/javascript; charset=utf-8",
    "Cache-Control": "public, max-age=86400",
  });
});

// MARK: - Predictive Accuracy

app.post("/polls/:id/predict", async (c) => {
  const userId = c.get("userId");
  const id = c.req.param("id");
  const body = await c.req.json<{ predicted_pct?: number }>();
  if (typeof body.predicted_pct !== "number") {
    return c.json({ error: "predicted_pct is required" }, 400);
  }
  try {
    const result = await recordPrediction(userId, id, body.predicted_pct);
    return c.json(result);
  } catch (err) {
    const status = (err as { httpStatus?: number }).httpStatus ?? 400;
    return c.json({ error: (err as Error).message }, status as 400);
  }
});

app.post("/polls/:id/predict/score", async (c) => {
  // Restricted to the poll's publisher OR an admin. Without this check any
  // signed-in user could settle predictions and award points on any poll.
  const id = c.req.param("id");
  const actor = await loadActor(c);
  if (!actor) return c.json({ error: "Forbidden" }, 403);

  if (actor.role !== "admin") {
    const poll = await prisma.poll.findUnique({
      where: { id },
      select: { publisherId: true },
    });
    if (!poll) return c.json({ error: "Poll not found" }, 404);
    if (poll.publisherId !== actor.id) {
      return c.json({ error: "Forbidden" }, 403);
    }
  }

  const result = await scorePollPredictions(id);
  return c.json(result);
});

app.get("/me/accuracy", async (c) => {
  const userId = c.get("userId");
  const stats = await userAccuracyStats(userId);
  return c.json(stats);
});

app.get("/accuracy/leaderboard", async (c) => {
  const limit = Math.min(50, Math.max(5, Number(c.req.query("limit") ?? "25")));
  const items = await predictionLeaderboard(limit);
  return c.json({ items });
});

// MARK: - Weekly Challenge

app.get("/challenges/this-week", async (c) => {
  const userId = c.get("userId");
  const ch = await getOrCreateThisWeekChallenge();
  const myPrediction = await prisma.weeklyChallengePrediction.findUnique({
    where: { challengeId_userId: { challengeId: ch.id, userId } },
  });
  const totalPredictions = await prisma.weeklyChallengePrediction.count({
    where: { challengeId: ch.id },
  });
  return c.json({
    id: ch.id,
    week_start: ch.weekStart,
    question: ch.question,
    description: ch.description,
    metric_label: ch.metricLabel,
    closes_at: ch.closesAt.toISOString(),
    status: ch.status,
    target_pct: ch.targetPct,
    reward_points: ch.rewardPoints,
    total_predictions: totalPredictions,
    my_prediction: myPrediction
      ? {
          predicted_pct: myPrediction.predictedPct,
          distance: myPrediction.distance,
          rank: myPrediction.rank,
        }
      : null,
  });
});

app.post("/challenges/:id/predict", async (c) => {
  const userId = c.get("userId");
  const id = c.req.param("id");
  const body = await c.req.json<{ predicted_pct?: number }>();
  if (typeof body.predicted_pct !== "number") {
    return c.json({ error: "predicted_pct is required" }, 400);
  }
  const created = await submitChallengePrediction(userId, id, body.predicted_pct);
  return c.json({ ok: true, id: created.id });
});

app.post("/admin/challenges/:id/settle", async (c) => {
  const actor = await loadActor(c);
  if (!actor || actor.role !== "admin") return c.json({ error: "Forbidden" }, 403);
  const id = c.req.param("id");
  const body = await c.req.json<{ actual_pct?: number }>();
  if (typeof body.actual_pct !== "number") return c.json({ error: "actual_pct is required" }, 400);
  const result = await settleChallenge(id, body.actual_pct);
  return c.json(result);
});

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// MARK: - Comments (الحوار بعد التصويت)

app.get("/polls/:id/comments", async (c) => {
  const id = c.req.param("id");
  const sort = (c.req.query("sort") as "top" | "new") ?? "top";
  const items = await listComments(id, sort);
  return c.json({ items });
});

app.post("/polls/:id/comments", async (c) => {
  const userId = c.get("userId");
  const id = c.req.param("id");
  const body = await c.req.json<{ body?: string }>();
  if (!body.body) return c.json({ error: "body is required" }, 400);
  try {
    const result = await postComment(userId, id, body.body);
    return c.json(result);
  } catch (err) {
    const status = (err as { httpStatus?: number }).httpStatus ?? 400;
    return c.json({ error: (err as Error).message }, status as 400 | 403);
  }
});

app.post("/comments/:id/vote", async (c) => {
  const userId = c.get("userId");
  const id = c.req.param("id");
  const body = await c.req.json<{ value?: 1 | -1 }>();
  if (body.value !== 1 && body.value !== -1) {
    return c.json({ error: "value must be 1 or -1" }, 400);
  }
  const result = await voteOnComment(userId, id, body.value);
  return c.json(result);
});

// MARK: - Realtime (SSE)

app.get("/events/dashboard", (c) => sseHandler(c));

// MARK: - Helpers

function requireSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error("JWT_SECRET is not configured");
  return secret;
}

// MARK: - Error handler

app.onError((err, c) => {
  console.error("[trendx] error:", err);
  const message = err instanceof Error ? err.message : String(err);
  return c.json({ error: message }, 400);
});

// MARK: - Boot

const port = Number(process.env.PORT ?? 3000);
const server = serve(
  { fetch: app.fetch, port, hostname: "0.0.0.0" },
  (info) => {
    console.log(
      `[trendx] railway-api listening on http://${info.address}:${info.port}`,
    );
  },
);

// Kick off the periodic analytics snapshot job. Disabled in test by setting
// SNAPSHOT_DISABLED=1.
if (process.env.SNAPSHOT_DISABLED !== "1") {
  startSnapshotJob();
}

if (process.env.DAILY_DISABLED !== "1") {
  startDailyJob();
}

// Optional one-time demo seeder. We run it in the background **after** the
// API server has started so Railway's healthcheck succeeds immediately;
// the heavy lifting (50 respondents + ~500 votes + 3 surveys) finishes a
// minute or two later without anyone noticing. Idempotent on re-run.
if (process.env.SEED_DEMO === "1") {
  setTimeout(async () => {
    try {
      console.log("[trendx] launching demo seeder in the background…");
      const { runDemoSeed } = await import("./seed-demo.js");
      await runDemoSeed();
      console.log("[trendx] demo seeder finished.");
    } catch (error) {
      console.error("[trendx] demo seeder failed (non-fatal):", error);
    }
  }, 5_000);
}

const shutdown = async () => {
  console.log("[trendx] shutting down…");
  server.close();
  await closeDb();
  process.exit(0);
};

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
