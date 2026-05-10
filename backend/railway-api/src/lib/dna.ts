/**
 * Opinion DNA — six axes derived from a user's vote history. Each
 * axis is a 0..100 scalar (50 = neutral). The set is rendered as a
 * radar chart in the app/web and can be shared as a PNG.
 *
 * Axes (interpretable to a layperson):
 *   1. progressive  ↔  traditional        (newness vs. heritage)
 *   2. economic     ↔  social             (priorities)
 *   3. optimistic   ↔  cautious           (outlook)
 *   4. individual   ↔  collective         (locus)
 *   5. risk-seeker  ↔  risk-averse        (decision style)
 *   6. early-adopter ↔ late-majority      (tech posture)
 *
 * The scoring is heuristic — keyword-driven against poll/option text —
 * so it will improve over time as poll authors tag their options. We
 * cache the result in `ai_insights` (entity_type='user_dna').
 */

import { prisma } from "../db.js";
import { aiJSON } from "./ai.js";

const AXES = [
  "progressive",
  "economic",
  "optimistic",
  "individual",
  "risk_seeker",
  "early_adopter",
] as const;
type Axis = typeof AXES[number];

const KEYWORDS: Record<Axis, { positive: string[]; negative: string[] }> = {
  progressive: {
    positive: ["جديد", "تغيير", "ابتكار", "حداثة", "تطوّر", "إصلاح", "modern"],
    negative: ["تقليدي", "أصيل", "تراث", "محافظ", "قديم", "كما هو"],
  },
  economic: {
    positive: ["مالي", "اقتصاد", "استثمار", "وظيفة", "راتب", "تكلفة", "أسعار", "عقار"],
    negative: ["اجتماعي", "أسرة", "نفسي", "صحة", "علاقات", "روحي", "ديني"],
  },
  optimistic: {
    positive: ["أفضل", "تحسّن", "نموّ", "تفاؤل", "ازدهار", "إيجابي", "أمل"],
    negative: ["أصعب", "أزمة", "تراجع", "قلق", "خوف", "سلبي", "كساد"],
  },
  individual: {
    positive: ["شخصي", "خاص", "أنا", "وحدي", "مستقل", "فردي"],
    negative: ["جماعي", "مجتمع", "نحن", "عائلة", "وطن", "مشترك"],
  },
  risk_seeker: {
    positive: ["مغامرة", "تجربة", "جرأة", "سفر", "استثمار", "إطلاق"],
    negative: ["أمان", "حذر", "ادّخار", "ضمان", "تأمين", "هدوء"],
  },
  early_adopter: {
    positive: ["تقنية", "ai", "ذكاء", "تطبيق", "رقمي", "بلوكتشين", "كهربائية", "متجدّدة"],
    negative: ["تقليدي", "ورقي", "يدوي", "كلاسيكي"],
  },
};

function scoreOptionForAxis(text: string, axis: Axis): number {
  const t = text.toLowerCase();
  const k = KEYWORDS[axis];
  let s = 0;
  for (const w of k.positive) if (t.includes(w)) s += 1;
  for (const w of k.negative) if (t.includes(w)) s -= 1;
  return s;
}

export type DNAPayload = {
  computed_at: string;
  sample_size: number;
  axes: Array<{
    key: Axis;
    label_high: string;
    label_low: string;
    score: number; // 0..100, 50 = neutral
  }>;
  archetype: {
    title: string;
    blurb: string;
  };
  share_caption: string;
};

const AXIS_LABELS: Record<Axis, { high: string; low: string }> = {
  progressive:    { high: "متجدِّد",      low: "محافظ على الأصول" },
  economic:       { high: "ذو نزعة اقتصاديّة", low: "ذو نزعة اجتماعيّة" },
  optimistic:     { high: "متفائل",        low: "حذِر" },
  individual:     { high: "فرديّ",          low: "جماعيّ" },
  risk_seeker:    { high: "مُغامر",          low: "محافظ على المخاطر" },
  early_adopter:  { high: "مبكّر التبنّي",   low: "متروٍّ في التبنّي" },
};

export async function computeOpinionDNA(userId: string): Promise<DNAPayload | null> {
  // Pull the user's recent vote history with option + poll context.
  const votes = await prisma.vote.findMany({
    where: { userId },
    take: 200,
    orderBy: { votedAt: "desc" },
    include: {
      option: { select: { text: true } },
      poll: { select: { title: true } },
    },
  });

  const pulses = await prisma.dailyPulseResponse.findMany({
    where: { userId },
    take: 200,
    orderBy: { respondedAt: "desc" },
    include: { pulse: { select: { question: true, options: true } } },
  });

  const total = votes.length + pulses.length;
  if (total < 3) return null;

  // Per-axis: sum scored signals, range = -10..10 → map to 0..100.
  const sums = AXES.reduce<Record<Axis, { score: number; count: number }>>(
    (acc, a) => ({ ...acc, [a]: { score: 0, count: 0 } }),
    {} as Record<Axis, { score: number; count: number }>,
  );

  for (const v of votes) {
    const t = `${v.poll?.title ?? ""} ${v.option?.text ?? ""}`;
    for (const a of AXES) {
      const s = scoreOptionForAxis(t, a);
      sums[a].score += s;
      sums[a].count += 1;
    }
  }
  for (const p of pulses) {
    const opts = (p.pulse?.options as Array<{ text: string }> | null) ?? [];
    const choice = opts[p.optionIndex]?.text ?? "";
    const t = `${p.pulse?.question ?? ""} ${choice}`;
    for (const a of AXES) {
      const s = scoreOptionForAxis(t, a);
      sums[a].score += s;
      sums[a].count += 1;
    }
  }

  const axes = AXES.map((a) => {
    const raw = sums[a].score; // -10..10ish
    const clamped = Math.max(-8, Math.min(8, raw));
    const pct = Math.round(50 + (clamped / 8) * 35); // gentle mapping → 15..85
    return {
      key: a,
      label_high: AXIS_LABELS[a].high,
      label_low: AXIS_LABELS[a].low,
      score: pct,
    };
  });

  const top = [...axes].sort((a, b) => Math.abs(b.score - 50) - Math.abs(a.score - 50)).slice(0, 2);

  const archetype = await aiJSON<{ title: string; blurb: string; caption: string }>({
    promptVersion: "user-dna-v1",
    system:
      "أنت كاتب TRENDX. ستستلم محاور هويّة الرأي للمستخدم. اكتب لقباً عربياً مميّزاً (3 كلمات أو أقل) وفقرة من جملتين تكشف هويّته بأسلوب أنيق محترم، ثم جملة قابلة للمشاركة على شبكات التواصل (caption). أعد JSON: { title, blurb, caption }.",
    fallback: {
      title: "صوت متوازن",
      blurb: "هويّتك في الرأي متّزنة بين أكثر من مدرسة، مع ميل واضح إلى التفاعل المسؤول.",
      caption: "هويّتي في الرأي متّزنة. اكتشف هويّتك على TRENDX.",
    },
    input: {
      sample_size: total,
      top_two_axes: top,
      all_axes: axes,
    },
  });

  return {
    computed_at: new Date().toISOString(),
    sample_size: total,
    axes,
    archetype: { title: archetype.title, blurb: archetype.blurb },
    share_caption: archetype.caption,
  };
}

const CACHE_TTL_MIN = 60 * 24; // refresh once per day

export async function getCachedOpinionDNA(userId: string, forceRefresh = false): Promise<DNAPayload | null> {
  if (!forceRefresh) {
    const cached = await prisma.aIInsight.findFirst({
      where: { entityType: "user_dna", entityId: userId, insightType: "user_dna" },
      orderBy: { generatedAt: "desc" },
    });
    if (cached) {
      const ageMin = (Date.now() - cached.generatedAt.getTime()) / 60_000;
      if (ageMin < CACHE_TTL_MIN) {
        return cached.content as unknown as DNAPayload;
      }
    }
  }
  const fresh = await computeOpinionDNA(userId);
  if (!fresh) return null;
  await prisma.aIInsight.create({
    data: {
      entityType: "user_dna",
      entityId: userId,
      insightType: "user_dna",
      modelUsed: process.env.OPENAI_MODEL ?? "gpt-4o-mini",
      promptVersion: "user-dna-v1",
      content: fresh as unknown as import("@prisma/client").Prisma.InputJsonValue,
    },
  });
  return fresh;
}
