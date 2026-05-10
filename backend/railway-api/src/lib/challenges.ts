/**
 * Weekly Challenge — every Sunday at 00:00 Riyadh, a new prediction
 * challenge is opened. Users submit a single guess (0..100) and
 * compete for the closest answer. Winners get a points bonus.
 */

import type { Prisma } from "@prisma/client";
import { prisma } from "../db.js";

function thisWeekStart(): string {
  const d = new Date();
  // Sunday rollover, 00:00 UTC. Saudi week starts Sunday.
  const day = d.getUTCDay();
  const offset = day; // 0..6 (Sun=0)
  d.setUTCDate(d.getUTCDate() - offset);
  d.setUTCHours(0, 0, 0, 0);
  return d.toISOString().slice(0, 10);
}

function endOfWeek(): Date {
  const d = new Date();
  const day = d.getUTCDay();
  const remaining = 6 - day;
  d.setUTCDate(d.getUTCDate() + remaining);
  d.setUTCHours(20, 59, 0, 0); // Saturday 23:59 Riyadh = 20:59 UTC
  return d;
}

const SEED_QUESTIONS: Array<{ question: string; metric: string; description?: string }> = [
  { question: "ما النسبة المتوقّعة لإقبال الأسر السعودية على الاستثمار في الأسهم خلال 2026؟", metric: "نسبة من سيستثمرون", description: "تخمين مبني على نبض المجتمع." },
  { question: "ما النسبة المتوقّعة لمن يفضّلون السيارات الكهربائية على البنزين؟", metric: "نسبة مفضّلي الكهربائية" },
  { question: "ما النسبة المتوقّعة لمن سيقضون إجازتهم داخل المملكة هذا الشتاء؟", metric: "نسبة السياحة الداخلية" },
  { question: "ما النسبة المتوقّعة لمن يستخدمون الذكاء الاصطناعي يومياً؟", metric: "نسبة المستخدمين اليوميين" },
  { question: "ما النسبة المتوقّعة لمن يتفاءلون بسوق العقار خلال 2026؟", metric: "نسبة المتفائلين" },
];

function pickSeedFor(weekStart: string) {
  let h = 0;
  for (let i = 0; i < weekStart.length; i += 1) h = (h * 31 + weekStart.charCodeAt(i)) & 0xffffffff;
  return SEED_QUESTIONS[Math.abs(h) % SEED_QUESTIONS.length];
}

export async function getOrCreateThisWeekChallenge() {
  const week = thisWeekStart();
  const existing = await prisma.weeklyChallenge.findUnique({ where: { weekStart: week } });
  if (existing) return existing;
  const seed = pickSeedFor(week);
  return prisma.weeklyChallenge.create({
    data: {
      weekStart: week,
      question: seed.question,
      description: seed.description ?? null,
      metricLabel: seed.metric,
      closesAt: endOfWeek(),
    },
  });
}

export async function submitChallengePrediction(
  userId: string,
  challengeId: string,
  predictedPct: number,
) {
  if (predictedPct < 0 || predictedPct > 100) throw new Error("Out of range");
  const existing = await prisma.weeklyChallengePrediction.findUnique({
    where: { challengeId_userId: { challengeId, userId } },
  });
  if (existing) return existing;
  return prisma.weeklyChallengePrediction.create({
    data: { challengeId, userId, predictedPct: Math.round(predictedPct) },
  });
}

/**
 * Settle the challenge once an admin (or cron) provides the actual
 * value. Computes ranks and awards points to top 10.
 */
export async function settleChallenge(
  challengeId: string,
  actualPct: number,
): Promise<{ winners: number }> {
  const challenge = await prisma.weeklyChallenge.findUnique({
    where: { id: challengeId },
    include: { predictions: true },
  });
  if (!challenge) throw new Error("Not found");

  const ranked = challenge.predictions
    .map((p) => ({ p, distance: Math.abs(p.predictedPct - actualPct) }))
    .sort((a, b) => a.distance - b.distance);

  await prisma.$transaction(async (tx) => {
    for (let i = 0; i < ranked.length; i += 1) {
      const r = ranked[i];
      await tx.weeklyChallengePrediction.update({
        where: { id: r.p.id },
        data: { distance: r.distance, rank: i + 1 },
      });
    }
    const top = ranked.slice(0, Math.min(10, ranked.length));
    for (const r of top) {
      const reward = Math.max(50, challenge.rewardPoints - r.p.id.length); // tiny variance
      const u = await tx.user.findUnique({ where: { id: r.p.userId } });
      if (!u) continue;
      const balance = u.points + reward;
      await tx.user.update({
        where: { id: r.p.userId },
        data: { points: balance, coins: balance / 6 },
      });
      await tx.pointsLedger.create({
        data: {
          userId: r.p.userId,
          amount: reward,
          type: "challenge_winner" as Prisma.PointsLedgerCreateInput["type"],
          refType: "weekly_challenge",
          refId: challengeId,
          description: `الفائز رقم ${r.p.rank ?? "—"} — ${challenge.question}`,
          balanceAfter: balance,
        },
      });
    }
    await tx.weeklyChallenge.update({
      where: { id: challengeId },
      data: { status: "settled", targetPct: actualPct },
    });
  });

  return { winners: Math.min(10, ranked.length) };
}
