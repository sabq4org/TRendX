/**
 * Predictive Accuracy — before voting, the user can guess what % of the
 * crowd will pick the leading option. After the poll closes (or any
 * time we score), we compute their distance from the truth and award
 * an accuracy score (0..100). The user's running average is their
 * "TRENDX Accuracy Score" — a leaderboard-worthy stat.
 */

import { prisma } from "../db.js";

export async function recordPrediction(
  userId: string,
  pollId: string,
  predictedPct: number,
): Promise<{ ok: true; prediction_id: string }> {
  if (predictedPct < 0 || predictedPct > 100) {
    throw Object.assign(new Error("predicted_pct out of range"), { httpStatus: 400 });
  }
  const existing = await prisma.votePrediction.findUnique({
    where: { pollId_userId: { pollId, userId } },
  });
  if (existing) return { ok: true, prediction_id: existing.id };

  const created = await prisma.votePrediction.create({
    data: { userId, pollId, predictedPct: Math.round(predictedPct) },
  });
  return { ok: true, prediction_id: created.id };
}

/**
 * Score all unscored predictions for a poll. Computes the actual
 * percentage of the leading option and persists per-user accuracy.
 */
export async function scorePollPredictions(pollId: string): Promise<{ scored: number; actual_pct: number | null }> {
  const counts = await prisma.vote.groupBy({
    by: ["optionId"],
    where: { pollId },
    _count: { _all: true },
  });
  if (counts.length === 0) return { scored: 0, actual_pct: null };
  const total = counts.reduce((s, c) => s + c._count._all, 0);
  const lead = counts.reduce((max, c) => (c._count._all > max._count._all ? c : max), counts[0]);
  const actualPct = Math.round((lead._count._all / total) * 100);

  const unscored = await prisma.votePrediction.findMany({
    where: { pollId, scoredAt: null },
  });
  let scored = 0;
  for (const p of unscored) {
    const distance = Math.abs(p.predictedPct - actualPct);
    const accuracy = Math.max(0, 100 - distance);
    await prisma.votePrediction.update({
      where: { id: p.id },
      data: {
        actualPct,
        distance,
        accuracy,
        scoredAt: new Date(),
      },
    });
    scored += 1;
  }
  return { scored, actual_pct: actualPct };
}

export async function userAccuracyStats(userId: string): Promise<{
  predictions: number;
  scored: number;
  average_accuracy: number;
  best_accuracy: number;
  rank_percentile: number;
}> {
  const [all, scored] = await Promise.all([
    prisma.votePrediction.count({ where: { userId } }),
    prisma.votePrediction.findMany({ where: { userId, NOT: { scoredAt: null } } }),
  ]);
  if (scored.length === 0) {
    return {
      predictions: all,
      scored: 0,
      average_accuracy: 0,
      best_accuracy: 0,
      rank_percentile: 0,
    };
  }
  const accs = scored.map((s) => s.accuracy ?? 0);
  const avg = accs.reduce((s, a) => s + a, 0) / accs.length;
  const best = Math.max(...accs);

  // Rank: count users with lower average than me.
  // Cheap-and-cheerful: aggregate top 1000 users for percentile calc.
  const others = await prisma.votePrediction.groupBy({
    by: ["userId"],
    where: { NOT: { scoredAt: null } },
    _avg: { accuracy: true },
    orderBy: { _avg: { accuracy: "desc" } },
    take: 1000,
  });
  let lower = 0;
  for (const o of others) {
    const acc = o._avg?.accuracy ?? 0;
    if (acc < avg) lower += 1;
  }
  const total = Math.max(1, others.length);
  const percentile = Math.round((lower / total) * 100);

  return {
    predictions: all,
    scored: scored.length,
    average_accuracy: Math.round(avg),
    best_accuracy: best,
    rank_percentile: percentile,
  };
}

export async function predictionLeaderboard(limit = 25): Promise<Array<{
  user_id: string;
  name: string;
  avatar_initial: string;
  predictions: number;
  average_accuracy: number;
}>> {
  const groups = await prisma.votePrediction.groupBy({
    by: ["userId"],
    where: { NOT: { scoredAt: null } },
    _avg: { accuracy: true },
    _count: { _all: true },
    orderBy: { _avg: { accuracy: "desc" } },
    take: limit,
  });

  if (groups.length === 0) return [];

  const users = await prisma.user.findMany({
    where: { id: { in: groups.map((g) => g.userId) } },
    select: { id: true, name: true, avatarInitial: true },
  });
  const map = new Map(users.map((u) => [u.id, u]));

  return groups.map((g) => {
    const u = map.get(g.userId);
    return {
      user_id: g.userId,
      name: u?.name ?? "—",
      avatar_initial: u?.avatarInitial ?? "؟",
      predictions: g._count._all,
      average_accuracy: Math.round(g._avg.accuracy ?? 0),
    };
  });
}
