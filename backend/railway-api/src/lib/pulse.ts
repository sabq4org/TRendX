/**
 * Daily Pulse — one national question per day. Closes at 23:59
 * Riyadh time. Results revealed instantly after the user responds.
 *
 *   - `getOrCreateTodayPulse()`  ensures today's pulse exists (idempotent).
 *   - `recordResponse()`         transactional vote + tally update + streak hit.
 *   - `previousPulseSummary()`   yesterday's pulse with AI narrative.
 *   - `pulseHistory(days)`       compact rollup for the timeline.
 */

import type { Prisma } from "@prisma/client";
import { prisma } from "../db.js";
import { ageGroupFromBirthYear } from "./demographics.js";
import { recordStreakHit } from "./streak.js";
import { aiJSON } from "./ai.js";

export type PulseOption = { text: string };

export type PulsePayload = {
  id: string;
  pulse_date: string;
  question: string;
  description: string | null;
  options: Array<{ index: number; text: string; votes: number; percentage: number }>;
  total_responses: number;
  status: string;
  closes_at: string;
  reward_points: number;
  topic_id: string | null;
  ai_summary: string | null;
};

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

function endOfTodayUtc(): Date {
  const d = new Date();
  d.setUTCHours(20, 59, 0, 0); // 23:59 Riyadh = 20:59 UTC
  return d;
}

/**
 * Default rotation of high-engagement national questions. Used when no
 * curator has scheduled tomorrow's pulse — the cron picks the next one
 * by hashing the date. Saudi-context, neutral, conversation-starting.
 */
const DEFAULT_QUESTIONS: Array<{ question: string; description?: string; options: string[] }> = [
  {
    question: "ما الأهم لك هذا الأسبوع؟",
    options: ["الأمن المالي", "الصحّة النفسيّة", "التعلّم الجديد", "الوقت مع العائلة"],
  },
  {
    question: "أين تقضي وقتك أكثر بعد العمل؟",
    options: ["البيت", "النوادي والمقاهي", "التطبيقات والشاشات", "الرياضة والمشي"],
  },
  {
    question: "أي تقنية تثق بها أكثر لمستقبل السعودية؟",
    options: ["الذكاء الاصطناعي", "الطاقة المتجدّدة", "السيارات الكهربائية", "البلوكتشين"],
  },
  {
    question: "كم تتوقّع أن تعيش خلال السنوات القادمة؟",
    options: ["أفضل بكثير", "أفضل قليلاً", "كما هو الآن", "أصعب من اليوم"],
  },
  {
    question: "أكثر ما يستحق الإنفاق عليه برأيك؟",
    options: ["السفر والتجارب", "التعليم والمهارات", "العقار والاستثمار", "الترفيه اليومي"],
  },
  {
    question: "أيّ قطاع يتطوّر بأقوى وتيرة في السعودية؟",
    options: ["السياحة والترفيه", "التقنية", "الصحّة", "التعليم"],
  },
  {
    question: "أكثر ما يُؤرّق جيلك حالياً؟",
    options: ["تكاليف المعيشة", "ضغط الوظيفة", "الصحّة النفسيّة", "غياب الوقت"],
  },
];

function pickDefaultByDate(date: string): typeof DEFAULT_QUESTIONS[number] {
  // Stable hash of yyyy-mm-dd → index
  let hash = 0;
  for (let i = 0; i < date.length; i += 1) hash = (hash * 31 + date.charCodeAt(i)) & 0xffffffff;
  return DEFAULT_QUESTIONS[Math.abs(hash) % DEFAULT_QUESTIONS.length];
}

function dtoFromRow(row: {
  id: string;
  pulseDate: string;
  question: string;
  description: string | null;
  options: Prisma.JsonValue;
  totalResponses: number;
  tallies: Prisma.JsonValue;
  status: string;
  closesAt: Date;
  rewardPoints: number;
  topicId: string | null;
  aiSummary: string | null;
}): PulsePayload {
  const opts = (row.options as PulseOption[] | null) ?? [];
  const tallies = (row.tallies as number[] | null) ?? [];
  const total = row.totalResponses;
  return {
    id: row.id,
    pulse_date: row.pulseDate,
    question: row.question,
    description: row.description,
    options: opts.map((o, i) => {
      const v = tallies[i] ?? 0;
      return {
        index: i,
        text: o.text,
        votes: v,
        percentage: total > 0 ? Number(((v / total) * 100).toFixed(1)) : 0,
      };
    }),
    total_responses: total,
    status: row.status,
    closes_at: row.closesAt.toISOString(),
    reward_points: row.rewardPoints,
    topic_id: row.topicId,
    ai_summary: row.aiSummary,
  };
}

export async function getOrCreateTodayPulse(): Promise<PulsePayload> {
  const today = todayIso();
  const existing = await prisma.dailyPulse.findUnique({ where: { pulseDate: today } });
  if (existing) return dtoFromRow(existing);

  const next = pickDefaultByDate(today);
  const created = await prisma.dailyPulse.create({
    data: {
      pulseDate: today,
      question: next.question,
      description: next.description ?? null,
      options: next.options.map((text) => ({ text })) as unknown as Prisma.InputJsonValue,
      tallies: new Array(next.options.length).fill(0) as unknown as Prisma.InputJsonValue,
      closesAt: endOfTodayUtc(),
      rewardPoints: 40,
    },
  });
  return dtoFromRow(created);
}

export async function getCurrentPulseForUser(userId: string): Promise<PulsePayload & {
  user_responded: boolean;
  user_choice: number | null;
}> {
  const pulse = await getOrCreateTodayPulse();
  const myResponse = await prisma.dailyPulseResponse.findUnique({
    where: { pulseId_userId: { pulseId: pulse.id, userId } },
    select: { optionIndex: true },
  });
  return {
    ...pulse,
    user_responded: !!myResponse,
    user_choice: myResponse?.optionIndex ?? null,
  };
}

export async function recordResponse(
  userId: string,
  optionIndex: number,
  predictedPct?: number,
): Promise<{
  pulse: PulsePayload;
  reward: number;
  streak: Awaited<ReturnType<typeof recordStreakHit>>;
  prediction_score: number | null;
}> {
  const pulse = await getOrCreateTodayPulse();
  const opts = (pulse.options ?? []);
  if (optionIndex < 0 || optionIndex >= opts.length) {
    throw new Error("optionIndex out of range");
  }
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new Error("User not found");

  const ageGroup = ageGroupFromBirthYear(user.birthYear);

  // Insert the response (unique on pulse_id + user_id) and update tally.
  // We use a transaction with a SELECT FOR UPDATE-style flow via Prisma.
  try {
    await prisma.$transaction(async (tx) => {
      await tx.dailyPulseResponse.create({
        data: {
          pulseId: pulse.id,
          userId,
          optionIndex,
          predictedPct: predictedPct ?? null,
          deviceType: user.deviceType,
          city: user.city,
          region: user.region,
          country: user.country,
          gender: user.gender,
          ageGroup,
        },
      });
      const fresh = await tx.dailyPulse.findUnique({ where: { id: pulse.id } });
      const tallies = ((fresh?.tallies as number[] | null) ?? new Array(opts.length).fill(0)).slice();
      while (tallies.length < opts.length) tallies.push(0);
      tallies[optionIndex] = (tallies[optionIndex] ?? 0) + 1;
      await tx.dailyPulse.update({
        where: { id: pulse.id },
        data: {
          tallies: tallies as unknown as Prisma.InputJsonValue,
          totalResponses: { increment: 1 },
        },
      });
    });
  } catch (err) {
    // Already responded — re-throw with a recognizable shape
    if ((err as { code?: string }).code === "P2002") {
      throw Object.assign(new Error("Already responded"), { httpStatus: 409 });
    }
    throw err;
  }

  // Reward + streak + ledger
  const streak = await recordStreakHit(userId, pulse.pulse_date);
  const baseReward = pulse.reward_points;
  const streakBonus = streak.delta === "+1" && streak.current_streak > 1
    ? Math.min(60, streak.current_streak * 2)
    : 0;
  const totalReward = baseReward + streakBonus;
  const newBalance = user.points + totalReward;

  await prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { points: newBalance, coins: newBalance / 6 },
    }),
    prisma.pointsLedger.create({
      data: {
        userId,
        amount: totalReward,
        type: "vote_reward",
        refType: "pulse",
        refId: pulse.id,
        description: `نبض اليوم${streakBonus > 0 ? ` + سلسلة ${streak.current_streak}` : ""}`,
        balanceAfter: newBalance,
      },
    }),
  ]);

  // Re-read fresh tally
  const fresh = await prisma.dailyPulse.findUnique({ where: { id: pulse.id } });
  const dto = fresh ? dtoFromRow(fresh) : pulse;

  // Predicted accuracy: distance to leading option's actual %
  let predictionScore: number | null = null;
  if (predictedPct !== undefined && predictedPct !== null && dto.options.length > 0) {
    const leading = [...dto.options].sort((a, b) => b.votes - a.votes)[0];
    const distance = Math.abs(leading.percentage - predictedPct);
    predictionScore = Math.max(0, Math.round(100 - distance));
  }

  return { pulse: dto, reward: totalReward, streak, prediction_score: predictionScore };
}

export async function previousPulseSummary(): Promise<PulsePayload | null> {
  const yesterday = new Date(Date.now() - 86_400_000).toISOString().slice(0, 10);
  const row = await prisma.dailyPulse.findUnique({ where: { pulseDate: yesterday } });
  return row ? dtoFromRow(row) : null;
}

export async function pulseHistory(days: number): Promise<Array<{
  pulse_date: string;
  question: string;
  total_responses: number;
  leading_option_text: string | null;
  leading_pct: number;
}>> {
  const rows = await prisma.dailyPulse.findMany({
    orderBy: { pulseDate: "desc" },
    take: days,
  });
  return rows.map((row) => {
    const opts = (row.options as PulseOption[] | null) ?? [];
    const tallies = (row.tallies as number[] | null) ?? [];
    let bestIdx = 0;
    let bestVal = -1;
    tallies.forEach((v, i) => { if (v > bestVal) { bestVal = v; bestIdx = i; } });
    return {
      pulse_date: row.pulseDate,
      question: row.question,
      total_responses: row.totalResponses,
      leading_option_text: opts[bestIdx]?.text ?? null,
      leading_pct: row.totalResponses > 0
        ? Number(((bestVal / row.totalResponses) * 100).toFixed(1))
        : 0,
    };
  });
}

/**
 * Generate the AI summary narrative for a closed pulse. Cheap call,
 * runs from the daily cron the morning after.
 */
export async function generatePulseAISummary(pulseId: string): Promise<string> {
  const row = await prisma.dailyPulse.findUnique({ where: { id: pulseId } });
  if (!row) return "";
  const opts = (row.options as PulseOption[] | null) ?? [];
  const tallies = (row.tallies as number[] | null) ?? [];
  const total = row.totalResponses;
  if (total < 5) return "العيّنة لم تكن كافية لاستخراج تفسير دقيق.";

  // Pull demographic split
  const responses = await prisma.dailyPulseResponse.findMany({
    where: { pulseId },
    select: { optionIndex: true, gender: true, ageGroup: true, city: true },
  });

  const result = await aiJSON<{ summary: string }>({
    promptVersion: "pulse-summary-v1",
    system:
      "أنت محرّر نبض TRENDX اليومي. اكتب جملتين بالعربية الفصحى تلخّصان نتيجة استبيان الأمس بأسلوب نشرة إخبارية، مع إشارة موجزة إلى أبرز ميل ديموغرافي. أعد JSON: { summary: string }",
    fallback: { summary: "جاء النبض اليومي بنتيجة واضحة، ويعكس ميلاً قويّاً للخيار الرائد." },
    input: {
      question: row.question,
      options: opts.map((o, i) => ({ text: o.text, votes: tallies[i] ?? 0 })),
      total,
      breakdown: responses.slice(0, 200), // cap input size
    },
  });

  await prisma.dailyPulse.update({
    where: { id: pulseId },
    data: { aiSummary: result.summary, status: "closed" },
  });
  return result.summary;
}
