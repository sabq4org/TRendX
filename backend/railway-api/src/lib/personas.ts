/**
 * Persona detection for surveys.
 *
 * Approach (no embeddings, no scipy — keeps Railway light):
 *  1. Build an answer vector for every completed response: an array of
 *     option_ids, ordered by question_id. Empty answers become null.
 *  2. Run k-medoids (Partitioning Around Medoids) with Hamming distance
 *     on those vectors. We pick K = clamp(2..5, ⌈log2(n)⌉).
 *  3. For each cluster, derive a synthetic profile (modal answer per
 *     question + the dominant demographic slice).
 *  4. Ask GPT-4o to NAME and DESCRIBE each cluster from its profile.
 *  5. Cache as an `ai_insights` row (insightType=`recommendation`,
 *     entityType=`survey_personas`).
 *
 * The output shape is shared by the Web dashboard and the iOS publisher
 * view — both consume the same JSON.
 */

import { prisma } from "../db.js";
import { Prisma } from "@prisma/client";
import { aiJSON } from "./ai.js";
import { PROMPT_VERSIONS, SYSTEM_PROMPTS } from "./ai-prompts.js";

const PERSONAS_TTL_MS = 6 * 60 * 60 * 1000; // 6 hours

export type PersonaProfile = {
  cluster_index: number;
  size: number;
  share_pct: number;
  /** Modal demographic profile for the cluster. */
  dominant_gender: string | null;
  dominant_age_group: string | null;
  dominant_city: string | null;
  /** AI-supplied name + description (Arabic). */
  name: string;
  description: string;
  traits: string[];
  representative_quote: string;
  /** Modal answers per question (id + chosen option text), helpful for UI. */
  modal_answers: Array<{ question_id: string; question_title: string; option_text: string }>;
};

export type PersonasPayload = {
  survey_id: string;
  k: number;
  sample_size: number;
  cached: boolean;
  generated_at: string;
  prompt_version: string;
  model: string;
  personas: PersonaProfile[];
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function hamming(a: (string | null)[], b: (string | null)[]): number {
  const len = Math.max(a.length, b.length);
  let d = 0;
  for (let i = 0; i < len; i += 1) if (a[i] !== b[i]) d += 1;
  return d;
}

function modeOf<T extends string | null>(arr: T[]): T | null {
  const counts = new Map<T, number>();
  for (const v of arr) counts.set(v, (counts.get(v) ?? 0) + 1);
  let best: T | null = null;
  let bestCount = -1;
  for (const [v, c] of counts) {
    if (c > bestCount && v !== null) {
      best = v;
      bestCount = c;
    }
  }
  return best;
}

/**
 * k-medoids (PAM) — simple iterative version. O(k * n * iterations) which
 * is fine for typical survey sizes (n < 5,000).
 */
function kMedoids(
  vectors: Array<(string | null)[]>,
  k: number,
  maxIter = 50,
): { assignments: number[]; medoidIndices: number[] } {
  const n = vectors.length;
  if (n === 0) return { assignments: [], medoidIndices: [] };
  if (n <= k) {
    return {
      assignments: vectors.map((_, i) => i),
      medoidIndices: vectors.map((_, i) => i),
    };
  }

  // Initial medoids: pick the most "central" point + farthest peers
  let medoids = [0];
  while (medoids.length < k) {
    let bestIdx = -1;
    let bestMinDist = -1;
    for (let i = 0; i < n; i += 1) {
      if (medoids.includes(i)) continue;
      const minDist = Math.min(...medoids.map((m) => hamming(vectors[i], vectors[m])));
      if (minDist > bestMinDist) {
        bestMinDist = minDist;
        bestIdx = i;
      }
    }
    if (bestIdx === -1) break;
    medoids.push(bestIdx);
  }

  let assignments = new Array(n).fill(0);
  for (let iter = 0; iter < maxIter; iter += 1) {
    // 1. Assign each point to nearest medoid
    for (let i = 0; i < n; i += 1) {
      let bestM = 0;
      let bestD = Infinity;
      for (let m = 0; m < medoids.length; m += 1) {
        const d = hamming(vectors[i], vectors[medoids[m]]);
        if (d < bestD) { bestD = d; bestM = m; }
      }
      assignments[i] = bestM;
    }
    // 2. Update each medoid to be the point in its cluster that minimizes
    //    total intra-cluster distance.
    let changed = false;
    for (let m = 0; m < medoids.length; m += 1) {
      const members = assignments
        .map((a, idx) => (a === m ? idx : -1))
        .filter((idx) => idx >= 0);
      if (members.length === 0) continue;
      let bestIdx = medoids[m];
      let bestSum = Infinity;
      for (const candidate of members) {
        let sum = 0;
        for (const other of members) sum += hamming(vectors[candidate], vectors[other]);
        if (sum < bestSum) { bestSum = sum; bestIdx = candidate; }
      }
      if (bestIdx !== medoids[m]) {
        medoids[m] = bestIdx;
        changed = true;
      }
    }
    if (!changed) break;
  }

  return { assignments, medoidIndices: medoids };
}

// ---------------------------------------------------------------------------
// Main entrypoint
// ---------------------------------------------------------------------------

type PersonaAIShape = {
  personas: Array<{
    name: string;
    description: string;
    traits: string[];
    representative_quote: string;
  }>;
};

export async function computeSurveyPersonas(
  surveyId: string,
  forceRefresh = false,
): Promise<PersonasPayload | null> {
  // 1. Cache check
  if (!forceRefresh) {
    const cached = await prisma.aIInsight.findFirst({
      where: {
        entityId: surveyId,
        entityType: "survey_personas",
        insightType: "recommendation",
      },
      orderBy: { generatedAt: "desc" },
    });
    if (cached && Date.now() - cached.generatedAt.getTime() < PERSONAS_TTL_MS) {
      const cachedContent = cached.content as unknown as Omit<PersonasPayload, "cached" | "generated_at" | "prompt_version" | "model">;
      return {
        ...cachedContent,
        cached: true,
        generated_at: cached.generatedAt.toISOString(),
        prompt_version: cached.promptVersion,
        model: cached.modelUsed,
      };
    }
  }

  // 2. Load survey + responses
  const survey = await prisma.survey.findUnique({
    where: { id: surveyId },
    include: {
      questions: {
        orderBy: { displayOrder: "asc" },
        include: { options: { orderBy: { displayOrder: "asc" } } },
      },
    },
  });
  if (!survey) return null;

  const responses = await prisma.surveyResponse.findMany({
    where: { surveyId, isComplete: true },
    include: { answers: true },
  });

  const questionIds = survey.questions.map((q) => q.id);
  if (responses.length < 6 || questionIds.length === 0) {
    // Not enough signal to cluster. Return a single "بانتظار عيّنة أكبر" persona
    return {
      survey_id: surveyId,
      k: 0,
      sample_size: responses.length,
      cached: false,
      generated_at: new Date().toISOString(),
      prompt_version: PROMPT_VERSIONS.personas,
      model: "n/a",
      personas: [],
    };
  }

  // 3. Build answer vectors
  const vectors: Array<(string | null)[]> = responses.map((r) => {
    const map = new Map(r.answers.map((a) => [a.questionId, a.optionId ?? null]));
    return questionIds.map((qid) => map.get(qid) ?? null);
  });

  // 4. Cluster
  const k = Math.max(2, Math.min(5, Math.ceil(Math.log2(responses.length))));
  const { assignments } = kMedoids(vectors, k);

  // 5. Build cluster profiles
  const optionTextById = new Map<string, string>();
  const questionTitleById = new Map<string, string>();
  for (const q of survey.questions) {
    questionTitleById.set(q.id, q.title);
    for (const opt of q.options) optionTextById.set(opt.id, opt.text);
  }

  const clusters: Array<{
    members: number[];
    modalAnswers: Array<{ question_id: string; question_title: string; option_text: string }>;
    dominantGender: string | null;
    dominantAge: string | null;
    dominantCity: string | null;
  }> = [];

  for (let m = 0; m < k; m += 1) {
    const memberIdx = assignments
      .map((a, i) => (a === m ? i : -1))
      .filter((i) => i >= 0);
    if (memberIdx.length === 0) continue;

    const memberResponses = memberIdx.map((i) => responses[i]);
    const modalAnswers: Array<{ question_id: string; question_title: string; option_text: string }> = [];
    for (const qid of questionIds) {
      const picks = memberResponses
        .map((r) => r.answers.find((a) => a.questionId === qid)?.optionId ?? null)
        .filter((v): v is string => v !== null);
      const modal = modeOf(picks);
      if (modal) {
        modalAnswers.push({
          question_id: qid,
          question_title: questionTitleById.get(qid) ?? "",
          option_text: optionTextById.get(modal) ?? "",
        });
      }
    }

    clusters.push({
      members: memberIdx,
      modalAnswers,
      dominantGender: modeOf(memberResponses.map((r) => r.gender)),
      dominantAge: modeOf(memberResponses.map((r) => r.ageGroup)),
      dominantCity: modeOf(memberResponses.map((r) => r.city)),
    });
  }

  // 6. Ask GPT-4o to name + describe each persona
  const aiInput = {
    survey_title: survey.title,
    survey_description: survey.description,
    clusters: clusters.map((c, i) => ({
      cluster_index: i,
      size: c.members.length,
      dominant_gender: c.dominantGender,
      dominant_age_group: c.dominantAge,
      dominant_city: c.dominantCity,
      modal_answers: c.modalAnswers,
    })),
  };

  const aiResult = await aiJSON<PersonaAIShape>({
    promptVersion: PROMPT_VERSIONS.personas,
    system: SYSTEM_PROMPTS.personas,
    fallback: {
      personas: clusters.map((c, i) => ({
        name: `الفئة ${i + 1}`,
        description: `مجموعة من ${c.members.length} مستجيب تتقاطع في إجاباتها.`,
        traits: c.modalAnswers.slice(0, 3).map((a) => a.option_text),
        representative_quote: c.modalAnswers[0]?.option_text ?? "",
      })),
    },
    input: aiInput,
  });

  // 7. Combine
  const totalSize = clusters.reduce((a, b) => a + b.members.length, 0);
  const personas: PersonaProfile[] = clusters.map((c, i) => {
    const ai = aiResult.personas?.[i] ?? {
      name: `الفئة ${i + 1}`,
      description: "",
      traits: [],
      representative_quote: "",
    };
    return {
      cluster_index: i,
      size: c.members.length,
      share_pct: totalSize > 0
        ? Number(((c.members.length / totalSize) * 100).toFixed(1))
        : 0,
      dominant_gender: c.dominantGender,
      dominant_age_group: c.dominantAge,
      dominant_city: c.dominantCity,
      name: ai.name,
      description: ai.description,
      traits: ai.traits ?? [],
      representative_quote: ai.representative_quote ?? "",
      modal_answers: c.modalAnswers,
    };
  });

  const payload: PersonasPayload = {
    survey_id: surveyId,
    k: clusters.length,
    sample_size: responses.length,
    cached: false,
    generated_at: new Date().toISOString(),
    prompt_version: aiResult.promptVersion ?? PROMPT_VERSIONS.personas,
    model: aiResult.modelUsed ?? "fallback",
    personas,
  };

  // 8. Cache
  await prisma.aIInsight.create({
    data: {
      entityId: surveyId,
      entityType: "survey_personas",
      insightType: "recommendation",
      modelUsed: payload.model,
      promptVersion: payload.prompt_version,
      content: payload as unknown as Prisma.InputJsonValue,
      latencyMs: aiResult.latencyMs ?? null,
    },
  });

  return payload;
}
