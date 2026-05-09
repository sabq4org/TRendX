import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { randomUUID } from "node:crypto";
import { sql, closePool } from "./db.js";
import {
  hashPassword,
  makeSalt,
  signToken,
  verifyPassword,
  verifyToken,
} from "./auth.js";

type Variables = {
  userId: string;
};

const app = new Hono<{ Variables: Variables }>();

app.use("*", cors({
  origin: "*",
  allowMethods: ["GET", "POST", "OPTIONS"],
  allowHeaders: ["Authorization", "Content-Type"],
}));

app.get("/health", (c) => c.json({ ok: true, service: "trendx-railway-api" }));

// MARK: - Auth

app.post("/auth/signup", async (c) => {
  const body = await c.req.json<{ name?: string; email?: string; password?: string }>();
  const email = (body.email ?? "").trim().toLowerCase();
  const name = (body.name ?? "").trim();
  const password = body.password ?? "";

  if (!email || !password || password.length < 6 || !name) {
    return c.json({ error: "Invalid signup payload" }, 400);
  }

  const salt = makeSalt();
  const passwordHash = await hashPassword(password, salt);

  try {
    const users = await sql`
      insert into beta_users (email, password_hash, password_salt)
      values (${email}, ${passwordHash}, ${salt})
      returning id, email
    `;
    const user = users[0]!;

    const profiles = await sql`
      insert into profiles (id, name, email, avatar_initial)
      values (${user.id}, ${name}, ${email}, ${name.slice(0, 1) || "م"})
      returning *
    `;

    return c.json({
      access_token: signToken({ sub: user.id, email }, requireSecret(c)),
      refresh_token: null,
      user: profiles[0],
    });
  } catch (error) {
    if (isUniqueViolation(error)) {
      return c.json({ error: "Email already registered" }, 409);
    }
    throw error;
  }
});

app.post("/auth/signin", async (c) => {
  const body = await c.req.json<{ email?: string; password?: string }>();
  const email = (body.email ?? "").trim().toLowerCase();
  const password = body.password ?? "";

  const users = await sql`select * from beta_users where email = ${email} limit 1`;
  const user = users[0];
  if (!user) return c.json({ error: "Invalid credentials" }, 401);

  const ok = await verifyPassword(password, user.password_salt, user.password_hash);
  if (!ok) return c.json({ error: "Invalid credentials" }, 401);

  const profiles = await sql`select * from profiles where id = ${user.id} limit 1`;
  return c.json({
    access_token: signToken({ sub: user.id, email }, requireSecret(c)),
    refresh_token: null,
    user: profiles[0],
  });
});

// MARK: - Auth middleware (everything below requires a token)

app.use("*", async (c, next) => {
  const path = c.req.path;
  const isPublic =
    path === "/health" ||
    path.startsWith("/auth/") ||
    c.req.method === "OPTIONS";
  if (isPublic) return next();

  const header = c.req.header("Authorization") ?? "";
  const token = header.replace(/^Bearer\s+/i, "");
  if (!token) return c.json({ error: "Missing token" }, 401);

  try {
    const payload = verifyToken(token, requireSecret(c));
    c.set("userId", payload.sub);
  } catch {
    return c.json({ error: "Invalid or expired token" }, 401);
  }

  return next();
});

// MARK: - Profile

app.get("/profile", async (c) => {
  const userId = c.get("userId");
  const profiles = await sql`select * from profiles where id = ${userId} limit 1`;
  if (!profiles[0]) return c.json({ error: "Profile not found" }, 404);
  return c.json(profiles[0]);
});

app.post("/profile", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{
    name: string;
    email: string;
    avatar_initial?: string;
  }>();

  const profiles = await sql`
    update profiles
    set name = ${body.name},
        email = ${body.email},
        avatar_initial = ${body.avatar_initial ?? body.name.slice(0, 1)},
        updated_at = now()
    where id = ${userId}
    returning *
  `;
  return c.json(profiles[0]);
});

// MARK: - Bootstrap

app.get("/bootstrap", async (c) => {
  const userId = c.get("userId");

  const [topics, profileRows, polls, options, votes] = await Promise.all([
    sql`select * from topics order by name asc`,
    sql`select completed_polls, followed_topics from profiles where id = ${userId} limit 1`,
    sql`select * from polls where status = 'نشط' order by created_at desc`,
    sql`select * from poll_options order by created_at asc`,
    sql`select poll_id, option_id from poll_votes where user_id = ${userId}`,
  ]);

  return c.json({
    topics,
    polls: decoratePolls(polls, options, votes, profileRows[0] ?? {}),
  });
});

// MARK: - Polls

app.post("/polls/create", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{
    poll: Record<string, any>;
    options: Array<{ text: string }>;
  }>();

  const profileRows = await sql`
    select name, avatar_initial from profiles where id = ${userId} limit 1
  `;
  const profile = profileRows[0];
  if (!profile) return c.json({ error: "Profile not found" }, 404);

  const poll = body.poll ?? {};
  const durationDays = Number(poll.duration_days ?? 7);
  const expiresAt =
    poll.expires_at ??
    new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000).toISOString();

  const inserted = await sql`
    insert into polls (
      title, description, image_url, cover_style,
      author_id, author_name, author_avatar,
      topic_id, topic_name, type, status,
      reward_points, duration_days, expires_at
    )
    values (
      ${poll.title}, ${poll.description ?? null}, ${poll.image_url ?? null}, ${poll.cover_style ?? null},
      ${userId}, ${profile.name}, ${profile.avatar_initial},
      ${poll.topic_id ?? null}, ${poll.topic_name ?? null}, ${poll.type ?? "اختيار واحد"}, ${poll.status ?? "نشط"},
      ${poll.reward_points ?? 50}, ${durationDays}, ${expiresAt}
    )
    returning *
  `;

  const newPoll = inserted[0]!;
  const insertedOptions: any[] = [];
  for (const option of body.options ?? []) {
    const rows = await sql`
      insert into poll_options (poll_id, text)
      values (${newPoll.id}, ${option.text})
      returning *
    `;
    insertedOptions.push(rows[0]);
  }

  return c.json({
    poll: {
      ...newPoll,
      options: insertedOptions,
      user_voted_option_id: null,
      is_bookmarked: false,
    },
  });
});

app.post("/polls/vote", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{
    poll_id?: string;
    pollId?: string;
    option_id?: string;
    optionId?: string;
  }>();
  const pollId = body.poll_id ?? body.pollId;
  const optionId = body.option_id ?? body.optionId;
  if (!pollId || !optionId) return c.json({ error: "Missing poll or option" }, 400);

  const inserted = await sql`
    insert into poll_votes (poll_id, option_id, user_id)
    values (${pollId}, ${optionId}, ${userId})
    on conflict (poll_id, user_id) do nothing
    returning id
  `;

  if (inserted.length === 0) {
    return c.json({ error: "Already voted" }, 409);
  }

  await sql`
    update poll_options
    set votes_count = votes_count + 1
    where id = ${optionId} and poll_id = ${pollId}
  `;

  const pollRows = await sql`
    update polls
    set total_votes = total_votes + 1
    where id = ${pollId}
    returning *
  `;
  const poll = pollRows[0]!;
  const points = Number(poll.reward_points ?? 0);

  const userRows = await sql`
    update profiles
    set points = points + ${points},
        coins = (points + ${points}) / 6.0,
        completed_polls = case
          when ${pollId}::uuid = any(completed_polls) then completed_polls
          else array_append(completed_polls, ${pollId}::uuid)
        end,
        updated_at = now()
    where id = ${userId}
    returning *
  `;

  const options = await sql`
    select * from poll_options where poll_id = ${pollId} order by created_at asc
  `;

  const insight = await aiInsight({ poll: { ...poll, options } });
  await sql`update polls set ai_insight = ${insight.insight} where id = ${pollId}`;
  await logAI(userId, "ai-poll-insight", String(poll.title ?? ""), insight);

  return c.json({
    poll: {
      ...poll,
      options,
      ai_insight: insight.insight,
      user_voted_option_id: optionId,
      is_bookmarked: false,
    },
    user: userRows[0],
    insight: insight.insight,
  });
});

// MARK: - Gifts & Redemptions

app.get("/gifts", async () => {
  const rows = await sql`
    select * from gifts where is_available = true order by points_required asc
  `;
  return Response.json(rows);
});

app.get("/redemptions", async (c) => {
  const userId = c.get("userId");
  const rows = await sql`
    select * from redemptions where user_id = ${userId} order by redeemed_at desc
  `;
  return c.json(rows);
});

app.post("/gifts/redeem", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{ gift_id?: string; giftId?: string }>();
  const giftId = body.gift_id ?? body.giftId;
  if (!giftId) return c.json({ error: "Missing gift" }, 400);

  const gifts = await sql`
    select * from gifts where id = ${giftId} and is_available = true limit 1
  `;
  const gift = gifts[0];
  if (!gift) return c.json({ error: "Gift not available" }, 404);

  const profiles = await sql`select * from profiles where id = ${userId} limit 1`;
  const profile = profiles[0];
  if (!profile) return c.json({ error: "Profile not found" }, 404);

  if (Number(profile.points) < Number(gift.points_required)) {
    return c.json({ error: "Insufficient points" }, 402);
  }

  const code = `TX-${randomUUID().slice(0, 6).toUpperCase()}`;

  const redemptions = await sql`
    insert into redemptions (
      user_id, gift_id, gift_name, brand_name,
      points_spent, value_in_riyal, code
    )
    values (
      ${userId}, ${gift.id}, ${gift.name}, ${gift.brand_name},
      ${gift.points_required}, ${gift.value_in_riyal}, ${code}
    )
    returning *
  `;

  const newPoints = Number(profile.points) - Number(gift.points_required);
  const userRows = await sql`
    update profiles
    set points = ${newPoints}, coins = ${newPoints / 6.0}, updated_at = now()
    where id = ${userId}
    returning *
  `;

  return c.json({ redemption: redemptions[0], user: userRows[0] });
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
  const output = await aiJSON(
    "Return Arabic JSON only with question, options, clarityScore, rationale.",
    body,
    fallback,
  );
  await logAI(userId, "ai-compose-poll", String(body.question ?? ""), output);
  return c.json(output);
});

app.post("/ai/poll-insight", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json<{ poll?: { title?: string } }>();
  const output = await aiInsight(body);
  await logAI(userId, "ai-poll-insight", String(body.poll?.title ?? ""), output);
  return c.json(output);
});

// MARK: - Helpers

function decoratePolls(
  polls: any[],
  options: any[],
  votes: any[],
  profile: any,
): any[] {
  const voteByPoll = new Map(votes.map((v) => [v.poll_id, v.option_id]));
  const completed = new Set<string>(profile?.completed_polls ?? []);
  const followed = new Set<string>(profile?.followed_topics ?? []);

  return polls
    .map((poll) => {
      const pollOptions = options.filter((o) => o.poll_id === poll.id);
      const totalVotes = Number(poll.total_votes ?? 0);
      return {
        ...poll,
        options: pollOptions.map((o) => ({
          ...o,
          percentage: totalVotes > 0
            ? (Number(o.votes_count) / totalVotes) * 100
            : 0,
        })),
        user_voted_option_id: voteByPoll.get(poll.id) ?? null,
        is_bookmarked: false,
        score:
          (followed.has(poll.topic_id) ? 70 : 0) +
          (!completed.has(poll.id) ? 45 : 0) +
          Math.min(totalVotes, 120) / 4,
      };
    })
    .sort((a, b) => b.score - a.score);
}

async function aiInsight(body: unknown) {
  return aiJSON(
    "Return Arabic JSON only with insight. Write one concise TRENDX poll insight.",
    body,
    {
      insight: "النتائج بدأت تتشكل، وكل صوت جديد يضيف وضوحاً أكبر للصورة.",
    },
  );
}

async function aiJSON(
  system: string,
  input: unknown,
  fallback: Record<string, unknown>,
): Promise<Record<string, unknown> & { latencyMs?: number }> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) return fallback;

  const started = Date.now();
  try {
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL ?? "gpt-4o-mini",
        input: [
          { role: "system", content: system },
          { role: "user", content: JSON.stringify(input) },
        ],
      }),
    });

    if (!response.ok) return fallback;

    const payload = (await response.json()) as { output_text?: string };
    const parsed = JSON.parse(payload.output_text ?? "{}");
    return { ...parsed, latencyMs: Date.now() - started };
  } catch (error) {
    console.warn("[trendx] aiJSON failed:", error);
    return fallback;
  }
}

async function logAI(
  userId: string,
  type: string,
  summary: string,
  output: unknown,
): Promise<void> {
  try {
    const trimmed = summary.length > 200 ? summary.slice(0, 200) : summary;
    const latency = (output as { latencyMs?: number }).latencyMs ?? null;
    await sql`
      insert into ai_events (user_id, type, input_summary, output, latency_ms)
      values (${userId}, ${type}, ${trimmed}, ${JSON.stringify(output)}, ${latency})
    `;
  } catch (error) {
    console.warn("[trendx] logAI failed:", error);
  }
}

function isUniqueViolation(error: unknown): boolean {
  return Boolean(error && typeof error === "object" && (error as any).code === "23505");
}

function requireSecret(c: { req: { url: string } }): string {
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

const shutdown = async () => {
  console.log("[trendx] shutting down…");
  server.close();
  await closePool();
  process.exit(0);
};

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
