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
  runSnapshotsNow,
  startSnapshotJob,
} from "./jobs/snapshot.js";
import { sseHandler, broadcastEvent } from "./events/sse.js";

// MARK: - Types

type Variables = {
  userId: string;
  userTier: string;
  userRole: string;
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

app.use("*", async (c, next) => {
  const path = c.req.path;
  const isPublic =
    path === "/" ||
    path === "/health" ||
    path.startsWith("/auth/") ||
    c.req.method === "OPTIONS";
  if (isPublic) return next();

  const header = c.req.header("Authorization") ?? "";
  const token = header.replace(/^Bearer\s+/i, "");
  if (!token) return c.json({ error: "Missing token" }, 401);

  try {
    const payload = verifyToken(token, requireSecret());
    c.set("userId", payload.sub);
  } catch {
    return c.json({ error: "Invalid or expired token" }, 401);
  }
  return next();
});

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
    phone?: string;
    gender?: string;
    birth_year?: number;
    city?: string;
    region?: string;
  }>();

  const updates: Record<string, unknown> = {};
  if (body.name !== undefined) updates.name = body.name;
  if (body.email !== undefined) updates.email = body.email.trim().toLowerCase();
  if (body.avatar_initial !== undefined) updates.avatarInitial = body.avatar_initial;
  if (body.avatar_url !== undefined) updates.avatarUrl = body.avatar_url;
  if (body.phone !== undefined) updates.phone = body.phone;
  if (body.gender !== undefined) updates.gender = normalizeGender(body.gender);
  if (body.birth_year !== undefined) updates.birthYear = body.birth_year;
  if (body.city !== undefined) updates.city = body.city;
  if (body.region !== undefined) updates.region = body.region;

  const user = await prisma.user.update({
    where: { id: c.get("userId") },
    data: updates,
  });
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
    if (newTotal % 100 === 0) {
      broadcastEvent({
        type: "vote_milestone",
        pollId,
        pollTitle: poll.title,
        total: newTotal,
        milestone: newTotal,
      });
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
  return Response.json(rows.map(giftDTO));
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
