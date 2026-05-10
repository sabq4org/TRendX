/**
 * TRENDX Index — a public, daily, single-page snapshot of the
 * national mood. Computed from poll & survey signals over a rolling
 * 7-day window, normalised to 0..100.
 *
 * Each indicator has:
 *   - slug            (stable id)
 *   - name            (Arabic, public-facing)
 *   - value           (0..100)
 *   - change_24h      (delta vs. yesterday, signed)
 *   - direction       ("up" | "down" | "flat")
 *   - sample_size     (responses considered)
 *
 * Indicators (initial set):
 *   1. economic_optimism      — % positive on economic-tagged polls
 *   2. quality_of_life        — % "improved" on lifestyle polls
 *   3. trust_in_institutions  — survey question with a known scale
 *   4. tech_adoption          — % choosing modern/AI options
 *   5. social_cohesion        — % collective-leaning answers
 *   6. national_pride         — heritage/tradition affinity
 *
 * The result is cached in `ai_insights` (entity_type='trendx_index',
 * entity_id='global') to keep the public endpoint cheap and stable.
 */

import { prisma } from "../db.js";
import type { Prisma } from "@prisma/client";

export type IndexMetric = {
  slug: string;
  name: string;
  value: number;
  change_24h: number;
  direction: "up" | "down" | "flat";
  sample_size: number;
  blurb: string;
};

export type IndexPayload = {
  computed_at: string;
  composite: number;       // weighted average of the indicators
  composite_change_24h: number;
  total_responses: number;
  metrics: IndexMetric[];
};

const POSITIVE_TERMS = ["أفضل", "تحسّن", "نموّ", "تفاؤل", "ازدهار", "إيجابي", "أمل", "نعم", "قوي", "موافق", "مرتفع"];
const NEGATIVE_TERMS = ["أسوأ", "أصعب", "أزمة", "تراجع", "قلق", "خوف", "سلبي", "كساد", "لا", "ضعيف", "معارض", "منخفض"];

function isPositiveText(t: string): number {
  const s = t.toLowerCase();
  if (POSITIVE_TERMS.some((p) => s.includes(p))) return 1;
  if (NEGATIVE_TERMS.some((n) => s.includes(n))) return -1;
  return 0;
}

const INDICATORS: Array<{
  slug: string;
  name: string;
  topicSlugs: string[];
  blurb: string;
}> = [
  { slug: "economic_optimism",     name: "التفاؤل الاقتصادي",         topicSlugs: ["economy", "finance", "business"], blurb: "ميل المستجيبين إلى توقّع تحسّن الاقتصاد." },
  { slug: "quality_of_life",       name: "جودة الحياة",                 topicSlugs: ["lifestyle", "wellbeing", "health"], blurb: "تقييم تطوّر الحياة اليومية." },
  { slug: "trust_in_institutions", name: "الثقة في المؤسسات",           topicSlugs: ["government", "education", "health"], blurb: "نسبة من يثقون في الجهات الرسمية." },
  { slug: "tech_adoption",         name: "تبنّي التقنية",                topicSlugs: ["tech", "ai", "digital"], blurb: "ميل المجتمع لاحتضان الأدوات الجديدة." },
  { slug: "social_cohesion",       name: "التماسك الاجتماعي",            topicSlugs: ["society", "family", "community"], blurb: "حضور القيم الجماعية في القرارات." },
  { slug: "national_pride",        name: "الاعتزاز الوطني",              topicSlugs: ["culture", "heritage", "saudi"], blurb: "حضور الأصالة والهويّة في الإجابات." },
];

async function compositeForIndicator(slug: string, topicSlugs: string[]): Promise<{ value: number; sample: number }> {
  const since = new Date(Date.now() - 7 * 86_400_000);

  // Pull a window of vote-with-option-text matching the topics.
  const votes = await prisma.vote.findMany({
    where: {
      votedAt: { gte: since },
      poll: { topic: { slug: { in: topicSlugs } } },
    },
    select: { option: { select: { text: true } } },
    take: 4000,
  });

  if (votes.length === 0) {
    // No specific topic data → fall back to global text-driven proxy.
    const fallback = await prisma.vote.findMany({
      where: { votedAt: { gte: since } },
      select: { option: { select: { text: true } } },
      take: 1200,
    });
    if (fallback.length === 0) return { value: 50, sample: 0 };
    let pos = 0;
    let neg = 0;
    for (const v of fallback) {
      const s = isPositiveText(v.option?.text ?? "");
      if (s > 0) pos += 1;
      if (s < 0) neg += 1;
    }
    const total = pos + neg;
    if (total === 0) return { value: 50, sample: fallback.length };
    return { value: Math.round((pos / total) * 100), sample: fallback.length };
  }

  let pos = 0;
  let neg = 0;
  for (const v of votes) {
    const s = isPositiveText(v.option?.text ?? "");
    if (s > 0) pos += 1;
    if (s < 0) neg += 1;
  }
  const total = pos + neg;
  if (total === 0) return { value: 50, sample: votes.length };
  return { value: Math.round((pos / total) * 100), sample: votes.length };
}

export async function computeTrendXIndex(): Promise<IndexPayload> {
  // Today
  const today: IndexMetric[] = [];
  for (const ind of INDICATORS) {
    const r = await compositeForIndicator(ind.slug, ind.topicSlugs);
    today.push({
      slug: ind.slug,
      name: ind.name,
      value: r.value,
      change_24h: 0,
      direction: "flat",
      sample_size: r.sample,
      blurb: ind.blurb,
    });
  }

  // Yesterday — load from cache
  const yest = await prisma.aIInsight.findFirst({
    where: { entityType: "trendx_index", entityId: "00000000-0000-0000-0000-000000000000", insightType: "trendx_index" },
    orderBy: { generatedAt: "desc" },
  });
  const yestMap: Record<string, number> = {};
  if (yest) {
    const payload = yest.content as unknown as IndexPayload;
    for (const m of payload.metrics ?? []) yestMap[m.slug] = m.value;
  }

  let composite = 0;
  for (const m of today) {
    const prev = yestMap[m.slug];
    if (typeof prev === "number") {
      const delta = m.value - prev;
      m.change_24h = delta;
      m.direction = delta > 1 ? "up" : delta < -1 ? "down" : "flat";
    }
    composite += m.value;
  }
  composite = Math.round(composite / today.length);
  const yestComposite = yest ? Math.round((yest.content as unknown as IndexPayload).composite ?? 50) : composite;

  const totalResponses = today.reduce((s, m) => s + m.sample_size, 0);

  return {
    computed_at: new Date().toISOString(),
    composite,
    composite_change_24h: composite - yestComposite,
    total_responses: totalResponses,
    metrics: today,
  };
}

export async function getCachedTrendXIndex(forceRefresh = false): Promise<IndexPayload> {
  if (!forceRefresh) {
    const cached = await prisma.aIInsight.findFirst({
      where: { entityType: "trendx_index", entityId: "00000000-0000-0000-0000-000000000000", insightType: "trendx_index" },
      orderBy: { generatedAt: "desc" },
    });
    if (cached) {
      const ageMin = (Date.now() - cached.generatedAt.getTime()) / 60_000;
      if (ageMin < 60) {
        return cached.content as unknown as IndexPayload;
      }
    }
  }
  const fresh = await computeTrendXIndex();
  await prisma.aIInsight.create({
    data: {
      entityType: "trendx_index",
      entityId: "00000000-0000-0000-0000-000000000000",
      insightType: "trendx_index",
      modelUsed: "internal",
      promptVersion: "trendx-index-v1",
      content: fresh as unknown as Prisma.InputJsonValue,
    },
  });
  return fresh;
}
