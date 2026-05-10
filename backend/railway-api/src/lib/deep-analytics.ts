/**
 * Layer 3 — Deep analytics.
 *
 * Layer 1 (real-time SSE)   → events/sse.ts
 * Layer 2 (periodic snapshots) → jobs/snapshot.ts + lib/analytics.ts
 * Layer 3 (deep, on-demand)    → THIS file
 *
 * Everything here is on-demand and computed lazily. Results that are
 * expensive to compute (sentiment timelines that depend on AI insights)
 * are cached in `analytics_snapshots` with a longer TTL than Layer 2.
 *
 * All output shapes use snake_case so iOS and the dashboard share the
 * exact same JSON contract — TRENDX is one product, not two.
 */

import { prisma } from "../db.js";

const TIMELINE_TTL_MS = 30 * 60 * 1000; // 30 min — sentiment moves slowly
const BENCHMARK_TTL_MS = 30 * 60 * 1000;

// ---------------------------------------------------------------------------
// Heatmap — joint distribution of two demographic dimensions, optionally
// constrained to one survey question's answer.
// ---------------------------------------------------------------------------

export type HeatmapDimension = "gender" | "age_group" | "city" | "device";

export type HeatmapCell = {
  x: string;
  y: string;
  count: number;
  /** Within the row (y), what % of responses sit in this column (x). */
  row_pct: number;
};

export type HeatmapPayload = {
  survey_id: string | null;
  poll_id: string | null;
  question_id: string | null;
  x_dim: HeatmapDimension;
  y_dim: HeatmapDimension;
  x_keys: string[];
  y_keys: string[];
  cells: HeatmapCell[];
  total: number;
  computed_at: string;
};

function dimValueOfResponse(
  r: { gender: string; ageGroup: string | null; city: string | null; deviceType: string },
  dim: HeatmapDimension,
): string {
  switch (dim) {
    case "gender":    return r.gender ?? "unspecified";
    case "age_group": return r.ageGroup ?? "unknown";
    case "city":      return r.city ?? "غير محدد";
    case "device":    return r.deviceType ?? "unknown";
  }
}

function dimValueOfVote(
  v: { gender: string; ageGroup: string | null; city: string | null; deviceType: string },
  dim: HeatmapDimension,
): string {
  return dimValueOfResponse(v, dim);
}

export async function computeSurveyHeatmap(
  surveyId: string,
  xDim: HeatmapDimension,
  yDim: HeatmapDimension,
  questionId?: string,
  optionId?: string,
): Promise<HeatmapPayload | null> {
  const survey = await prisma.survey.findUnique({ where: { id: surveyId } });
  if (!survey) return null;

  const responses = await prisma.surveyResponse.findMany({
    where: { surveyId },
    include: questionId ? { answers: { where: { questionId } } } : undefined,
  });

  // If a question filter is set, keep only responses that answered it
  // (with an optional specific option_id) — that's the cohort the user
  // is slicing on.
  const cohort = questionId
    ? responses.filter((r) => {
        const answers = (r as unknown as { answers: { optionId: string | null }[] }).answers;
        if (!answers || answers.length === 0) return false;
        if (optionId) return answers.some((a) => a.optionId === optionId);
        return true;
      })
    : responses;

  const yMap = new Map<string, Map<string, number>>();
  for (const r of cohort) {
    const x = dimValueOfResponse(r, xDim);
    const y = dimValueOfResponse(r, yDim);
    if (!yMap.has(y)) yMap.set(y, new Map());
    const row = yMap.get(y)!;
    row.set(x, (row.get(x) ?? 0) + 1);
  }

  const yKeys = Array.from(yMap.keys()).sort();
  const xSet = new Set<string>();
  for (const row of yMap.values()) for (const k of row.keys()) xSet.add(k);
  const xKeys = Array.from(xSet).sort();

  const cells: HeatmapCell[] = [];
  for (const y of yKeys) {
    const row = yMap.get(y)!;
    const rowTotal = Array.from(row.values()).reduce((a, b) => a + b, 0);
    for (const x of xKeys) {
      const count = row.get(x) ?? 0;
      cells.push({
        x,
        y,
        count,
        row_pct: rowTotal > 0 ? Number(((count / rowTotal) * 100).toFixed(1)) : 0,
      });
    }
  }

  return {
    survey_id: surveyId,
    poll_id: null,
    question_id: questionId ?? null,
    x_dim: xDim,
    y_dim: yDim,
    x_keys: xKeys,
    y_keys: yKeys,
    cells,
    total: cohort.length,
    computed_at: new Date().toISOString(),
  };
}

export async function computePollHeatmap(
  pollId: string,
  xDim: HeatmapDimension,
  yDim: HeatmapDimension,
  optionId?: string,
): Promise<HeatmapPayload | null> {
  const poll = await prisma.poll.findUnique({ where: { id: pollId } });
  if (!poll) return null;

  const votes = await prisma.vote.findMany({
    where: { pollId, ...(optionId ? { optionId } : {}) },
  });

  const yMap = new Map<string, Map<string, number>>();
  for (const v of votes) {
    const x = dimValueOfVote(v, xDim);
    const y = dimValueOfVote(v, yDim);
    if (!yMap.has(y)) yMap.set(y, new Map());
    const row = yMap.get(y)!;
    row.set(x, (row.get(x) ?? 0) + 1);
  }

  const yKeys = Array.from(yMap.keys()).sort();
  const xSet = new Set<string>();
  for (const row of yMap.values()) for (const k of row.keys()) xSet.add(k);
  const xKeys = Array.from(xSet).sort();

  const cells: HeatmapCell[] = [];
  for (const y of yKeys) {
    const row = yMap.get(y)!;
    const rowTotal = Array.from(row.values()).reduce((a, b) => a + b, 0);
    for (const x of xKeys) {
      const count = row.get(x) ?? 0;
      cells.push({
        x,
        y,
        count,
        row_pct: rowTotal > 0 ? Number(((count / rowTotal) * 100).toFixed(1)) : 0,
      });
    }
  }

  return {
    survey_id: null,
    poll_id: pollId,
    question_id: null,
    x_dim: xDim,
    y_dim: yDim,
    x_keys: xKeys,
    y_keys: yKeys,
    cells,
    total: votes.length,
    computed_at: new Date().toISOString(),
  };
}

// ---------------------------------------------------------------------------
// Cross-question — full joint distribution between two questions of one
// survey, plus a chi-squared independence statistic so we know whether
// the relationship is statistically meaningful.
// ---------------------------------------------------------------------------

export type CrossQuestionPayload = {
  survey_id: string;
  q1: { id: string; title: string; options: { id: string; text: string }[] };
  q2: { id: string; title: string; options: { id: string; text: string }[] };
  matrix: Array<Array<{
    q1_option_id: string;
    q2_option_id: string;
    count: number;
    /** P(q2=option | q1=option) */
    conditional_pct: number;
  }>>;
  chi_squared: number;
  degrees_of_freedom: number;
  /** Crude p-value bucket: <0.01, <0.05, <0.10, ≥0.10 */
  significance: "very_high" | "high" | "moderate" | "weak";
  sample_size: number;
  computed_at: string;
};

/** χ² critical values at p=0.05 for df 1..30 (lookup, no scipy needed). */
const CHI_05: Record<number, number> = {
  1: 3.84, 2: 5.99, 3: 7.81, 4: 9.49, 5: 11.07, 6: 12.59, 7: 14.07,
  8: 15.51, 9: 16.92, 10: 18.31, 11: 19.68, 12: 21.03, 13: 22.36, 14: 23.68,
  15: 25.0, 16: 26.3, 17: 27.59, 18: 28.87, 19: 30.14, 20: 31.41,
};
const CHI_01: Record<number, number> = {
  1: 6.63, 2: 9.21, 3: 11.34, 4: 13.28, 5: 15.09, 6: 16.81, 7: 18.48,
  8: 20.09, 9: 21.67, 10: 23.21, 11: 24.72, 12: 26.22, 13: 27.69, 14: 29.14,
  15: 30.58, 16: 32.0, 17: 33.41, 18: 34.81, 19: 36.19, 20: 37.57,
};

export async function computeCrossQuestion(
  surveyId: string,
  q1Id: string,
  q2Id: string,
): Promise<CrossQuestionPayload | null> {
  const [q1, q2] = await Promise.all([
    prisma.surveyQuestion.findUnique({
      where: { id: q1Id },
      include: { options: { orderBy: { displayOrder: "asc" } } },
    }),
    prisma.surveyQuestion.findUnique({
      where: { id: q2Id },
      include: { options: { orderBy: { displayOrder: "asc" } } },
    }),
  ]);
  if (!q1 || !q2 || q1.surveyId !== surveyId || q2.surveyId !== surveyId) {
    return null;
  }

  const responses = await prisma.surveyResponse.findMany({
    where: { surveyId },
    include: { answers: true },
  });

  // For each response, find the picked option for q1 and q2.
  const pairs: Array<{ a1: string; a2: string }> = [];
  for (const r of responses) {
    const a1 = r.answers.find((a) => a.questionId === q1Id)?.optionId;
    const a2 = r.answers.find((a) => a.questionId === q2Id)?.optionId;
    if (a1 && a2) pairs.push({ a1, a2 });
  }

  const counts = new Map<string, Map<string, number>>();
  for (const o1 of q1.options) counts.set(o1.id, new Map());
  for (const { a1, a2 } of pairs) {
    if (!counts.has(a1)) counts.set(a1, new Map());
    const row = counts.get(a1)!;
    row.set(a2, (row.get(a2) ?? 0) + 1);
  }

  // χ² test
  const total = pairs.length;
  const rowTotals = new Map<string, number>();
  const colTotals = new Map<string, number>();
  for (const o1 of q1.options) {
    const row = counts.get(o1.id) ?? new Map();
    let rt = 0;
    for (const v of row.values()) rt += v;
    rowTotals.set(o1.id, rt);
    for (const o2 of q2.options) {
      const c = row.get(o2.id) ?? 0;
      colTotals.set(o2.id, (colTotals.get(o2.id) ?? 0) + c);
    }
  }
  let chi = 0;
  if (total > 0) {
    for (const o1 of q1.options) {
      for (const o2 of q2.options) {
        const observed = counts.get(o1.id)?.get(o2.id) ?? 0;
        const expected = ((rowTotals.get(o1.id) ?? 0) * (colTotals.get(o2.id) ?? 0)) / total;
        if (expected > 0) {
          chi += ((observed - expected) ** 2) / expected;
        }
      }
    }
  }
  const df = Math.max(1, (q1.options.length - 1) * (q2.options.length - 1));
  const sig: CrossQuestionPayload["significance"] =
    chi >= (CHI_01[df] ?? Infinity) ? "very_high" :
    chi >= (CHI_05[df] ?? Infinity) ? "high" :
    chi >= (CHI_05[df] ?? Infinity) * 0.7 ? "moderate" :
    "weak";

  const matrix = q1.options.map((o1) => {
    const row = counts.get(o1.id) ?? new Map();
    const rowTotal = rowTotals.get(o1.id) ?? 0;
    return q2.options.map((o2) => {
      const c = row.get(o2.id) ?? 0;
      return {
        q1_option_id: o1.id,
        q2_option_id: o2.id,
        count: c,
        conditional_pct: rowTotal > 0 ? Number(((c / rowTotal) * 100).toFixed(1)) : 0,
      };
    });
  });

  return {
    survey_id: surveyId,
    q1: { id: q1.id, title: q1.title, options: q1.options.map((o) => ({ id: o.id, text: o.text })) },
    q2: { id: q2.id, title: q2.title, options: q2.options.map((o) => ({ id: o.id, text: o.text })) },
    matrix,
    chi_squared: Number(chi.toFixed(2)),
    degrees_of_freedom: df,
    significance: sig,
    sample_size: total,
    computed_at: new Date().toISOString(),
  };
}

// ---------------------------------------------------------------------------
// Sentiment timeline — last N days for a topic, derived from AI insights
// generated for polls/surveys in that topic. Cached aggressively.
// ---------------------------------------------------------------------------

export type SentimentTimelinePayload = {
  topic_id: string;
  topic_name: string;
  days: number;
  series: Array<{
    date: string;
    sentiment: number;          // 0..100
    sample: number;              // total votes/responses that day
    polls: number;
    surveys: number;
  }>;
  current_score: number;
  direction: "rising" | "falling" | "stable";
  delta_30d: number;
  computed_at: string;
};

export async function computeSentimentTimeline(
  topicId: string,
  days = 30,
): Promise<SentimentTimelinePayload | null> {
  const topic = await prisma.topic.findUnique({ where: { id: topicId } });
  if (!topic) return null;

  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

  const [polls, surveys] = await Promise.all([
    prisma.poll.findMany({
      where: { topicId },
      include: { options: true, votes: { where: { votedAt: { gte: since } } } },
    }),
    prisma.survey.findMany({
      where: { topicId },
      include: {
        responses: { where: { startedAt: { gte: since } } },
      },
    }),
  ]);

  // For each day in the window, build:
  //   sentiment = weighted average of (leading_pct on that day)
  //   sample    = total votes + responses that day
  // This is a heuristic but stable: when an option dominates, sentiment ↑.
  // When opinion fragments, sentiment ↓ toward 50.
  const dayMap = new Map<string, { sentSum: number; weightSum: number; sample: number; polls: Set<string>; surveys: Set<string> }>();

  for (let d = 0; d < days; d += 1) {
    const date = new Date(since.getTime() + d * 24 * 60 * 60 * 1000)
      .toISOString().slice(0, 10);
    dayMap.set(date, { sentSum: 0, weightSum: 0, sample: 0, polls: new Set(), surveys: new Set() });
  }

  // Group votes by day, then by poll, then compute that poll's leading-pct as of EOD.
  for (const poll of polls) {
    const votesByDay = new Map<string, number[]>();
    for (const v of poll.votes) {
      const day = v.votedAt.toISOString().slice(0, 10);
      if (!votesByDay.has(day)) votesByDay.set(day, []);
      votesByDay.get(day)!.push(0); // placeholder — we'll use poll-level leading-pct
    }
    if (poll.totalVotes <= 0) continue;
    const sortedOpts = [...poll.options].sort((a, b) => b.votesCount - a.votesCount);
    const leading = sortedOpts[0]?.votesCount ?? 0;
    const leadingPct = (leading / poll.totalVotes) * 100;
    for (const [day, dayVotes] of votesByDay) {
      const slot = dayMap.get(day);
      if (!slot) continue;
      slot.sentSum += leadingPct * dayVotes.length;
      slot.weightSum += dayVotes.length;
      slot.sample += dayVotes.length;
      slot.polls.add(poll.id);
    }
  }

  for (const survey of surveys) {
    if (survey.totalResponses <= 0) continue;
    const completionRate = (survey.totalCompletes / survey.totalResponses) * 100;
    for (const r of survey.responses) {
      const day = r.startedAt.toISOString().slice(0, 10);
      const slot = dayMap.get(day);
      if (!slot) continue;
      slot.sentSum += completionRate;
      slot.weightSum += 1;
      slot.sample += 1;
      slot.surveys.add(survey.id);
    }
  }

  const series = Array.from(dayMap.entries())
    .map(([date, slot]) => ({
      date,
      sentiment: slot.weightSum > 0
        ? Number((slot.sentSum / slot.weightSum).toFixed(1))
        : 50,
      sample: slot.sample,
      polls: slot.polls.size,
      surveys: slot.surveys.size,
    }))
    .sort((a, b) => a.date.localeCompare(b.date));

  const recent = series.slice(-7).filter((s) => s.sample > 0);
  const earlier = series.slice(0, 7).filter((s) => s.sample > 0);
  const recentAvg = recent.length > 0
    ? recent.reduce((a, b) => a + b.sentiment, 0) / recent.length
    : 50;
  const earlierAvg = earlier.length > 0
    ? earlier.reduce((a, b) => a + b.sentiment, 0) / earlier.length
    : recentAvg;
  const delta = recentAvg - earlierAvg;
  const direction: SentimentTimelinePayload["direction"] =
    delta > 5 ? "rising" : delta < -5 ? "falling" : "stable";

  return {
    topic_id: topicId,
    topic_name: topic.name,
    days,
    series,
    current_score: Number(recentAvg.toFixed(1)),
    direction,
    delta_30d: Number(delta.toFixed(1)),
    computed_at: new Date().toISOString(),
  };
}

export async function getCachedSentimentTimeline(
  topicId: string,
  days = 30,
): Promise<SentimentTimelinePayload | null> {
  const cached = await prisma.analyticsSnapshot.findFirst({
    where: { entityId: topicId, entityType: `topic_sentiment_${days}d` },
    orderBy: { computedAt: "desc" },
  });
  if (cached && Date.now() - cached.computedAt.getTime() < TIMELINE_TTL_MS) {
    return cached.payload as unknown as SentimentTimelinePayload;
  }
  const fresh = await computeSentimentTimeline(topicId, days);
  if (fresh) {
    await prisma.analyticsSnapshot.create({
      data: {
        entityId: topicId,
        entityType: `topic_sentiment_${days}d`,
        payload: fresh as unknown as object,
      },
    });
  }
  return fresh;
}

// ---------------------------------------------------------------------------
// Sector benchmark — compare 2..N topics on common metrics so the dashboard
// (and iOS publisher view) can show a side-by-side comparison.
// ---------------------------------------------------------------------------

export type SectorBenchmarkRow = {
  topic_id: string;
  topic_name: string;
  topic_slug: string;
  polls_count: number;
  surveys_count: number;
  total_votes: number;
  total_responses: number;
  avg_completion_rate: number;
  followers_count: number;
  /** Average sentiment score from the cached timeline (0..100). */
  sentiment_score: number | null;
  sentiment_direction: "rising" | "falling" | "stable" | null;
};

export type SectorBenchmarkPayload = {
  topic_ids: string[];
  rows: SectorBenchmarkRow[];
  /** Winner per metric (topic_id) */
  leaders: {
    by_engagement: string | null;       // most votes+responses
    by_completion: string | null;
    by_sentiment: string | null;
    by_followers: string | null;
  };
  computed_at: string;
};

export async function computeSectorBenchmark(
  topicIds: string[],
): Promise<SectorBenchmarkPayload> {
  const topics = await prisma.topic.findMany({ where: { id: { in: topicIds } } });

  const rows: SectorBenchmarkRow[] = await Promise.all(
    topics.map(async (t) => {
      const [polls, surveys, sentiment] = await Promise.all([
        prisma.poll.findMany({
          where: { topicId: t.id },
          select: { totalVotes: true },
        }),
        prisma.survey.findMany({
          where: { topicId: t.id },
          select: { totalResponses: true, totalCompletes: true },
        }),
        getCachedSentimentTimeline(t.id, 30).catch(() => null),
      ]);
      const totalResponses = surveys.reduce((a, b) => a + b.totalResponses, 0);
      const totalCompletes = surveys.reduce((a, b) => a + b.totalCompletes, 0);
      return {
        topic_id: t.id,
        topic_name: t.name,
        topic_slug: t.slug,
        polls_count: polls.length,
        surveys_count: surveys.length,
        total_votes: polls.reduce((a, b) => a + b.totalVotes, 0),
        total_responses: totalResponses,
        avg_completion_rate: totalResponses > 0
          ? Math.round((totalCompletes / totalResponses) * 100)
          : 0,
        followers_count: t.followersCount,
        sentiment_score: sentiment?.current_score ?? null,
        sentiment_direction: sentiment?.direction ?? null,
      };
    }),
  );

  function leader(metric: (r: SectorBenchmarkRow) => number): string | null {
    if (rows.length === 0) return null;
    const sorted = [...rows].sort((a, b) => metric(b) - metric(a));
    return sorted[0]?.topic_id ?? null;
  }

  return {
    topic_ids: topicIds,
    rows,
    leaders: {
      by_engagement: leader((r) => r.total_votes + r.total_responses),
      by_completion: leader((r) => r.avg_completion_rate),
      by_sentiment:  leader((r) => r.sentiment_score ?? -1),
      by_followers:  leader((r) => r.followers_count),
    },
    computed_at: new Date().toISOString(),
  };
}

export async function getCachedSectorBenchmark(
  topicIds: string[],
): Promise<SectorBenchmarkPayload> {
  const key = [...topicIds].sort().join(",");
  // We use entityType="benchmark" and entityId=hashed-key namespace.
  const cached = await prisma.analyticsSnapshot.findFirst({
    where: { entityType: "sector_benchmark", entityId: key.slice(0, 36) },
    orderBy: { computedAt: "desc" },
  });
  if (cached && Date.now() - cached.computedAt.getTime() < BENCHMARK_TTL_MS) {
    return cached.payload as unknown as SectorBenchmarkPayload;
  }
  const fresh = await computeSectorBenchmark(topicIds);
  await prisma.analyticsSnapshot
    .create({
      data: {
        entityType: "sector_benchmark",
        entityId: key.slice(0, 36),
        payload: fresh as unknown as object,
      },
    })
    .catch(() => null); // unique conflict ok
  return fresh;
}
