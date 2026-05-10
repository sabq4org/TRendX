/**
 * Audience Marketplace — publishers describe a slice of the population
 * (e.g. "Saudi women, 25-34, in Riyadh, who use iOS") and we tell them
 * how many active users match, plus a fair price.
 *
 * Pricing model:
 *   base_per_response = 8 SAR  (covers reward + AI report + margin)
 *   matched_count * base_per_response = list price
 *   tier discount: enterprise -25%, premium -15%
 */

import type { Prisma } from "@prisma/client";
import { prisma } from "../db.js";
import { ageGroupFromBirthYear } from "./demographics.js";

export type AudienceCriteria = {
  gender?: ("male" | "female" | "other" | "unspecified")[];
  age_groups?: string[]; // "18-24", ...
  cities?: string[];
  regions?: string[];
  devices?: string[]; // "ios" | "android" | "web"
  topic_ids?: string[]; // historic interest in any of these topics
};

export type AudienceEstimate = {
  available_count: number;
  estimated_price_sar: number;
  per_response_price_sar: number;
  median_response_minutes: number; // expected delivery speed
  representativeness: number;       // 0..100 vs national distribution
  breakdown: {
    by_gender: Record<string, number>;
    by_age_group: Record<string, number>;
    by_city: Record<string, number>;
  };
};

const BASE_PER_RESPONSE = 8.0; // SAR
const TIER_DISCOUNT: Record<string, number> = {
  free: 0,
  premium: 0.15,
  enterprise: 0.25,
};

function whereFromCriteria(c: AudienceCriteria): Prisma.UserWhereInput {
  const where: Prisma.UserWhereInput = {
    role: "respondent", // only count regular respondents, not publishers/admins
  };
  if (c.gender && c.gender.length > 0) {
    where.gender = { in: c.gender as Prisma.UserWhereInput["gender"] extends infer U ? U : never } as never;
  }
  if (c.cities && c.cities.length > 0) {
    where.city = { in: c.cities };
  }
  if (c.regions && c.regions.length > 0) {
    where.region = { in: c.regions };
  }
  if (c.devices && c.devices.length > 0) {
    where.deviceType = { in: c.devices } as never;
  }
  return where;
}

function ageGroupForUser(birthYear: number | null): string {
  return ageGroupFromBirthYear(birthYear);
}

export async function estimateAudience(
  criteria: AudienceCriteria,
  publisherTier: string = "free",
): Promise<AudienceEstimate> {
  const where = whereFromCriteria(criteria);

  // Pull a representative sample (cap at 5000) and apply post-filters
  // that aren't easily expressed in SQL (age_groups, topic affinity).
  const candidates = await prisma.user.findMany({
    where,
    select: {
      id: true,
      gender: true,
      birthYear: true,
      city: true,
      region: true,
      deviceType: true,
    },
    take: 5000,
  });

  let filtered = candidates;
  if (criteria.age_groups && criteria.age_groups.length > 0) {
    const set = new Set(criteria.age_groups);
    filtered = filtered.filter((u) => set.has(ageGroupForUser(u.birthYear)));
  }

  if (criteria.topic_ids && criteria.topic_ids.length > 0) {
    const ids = await prisma.vote.findMany({
      where: {
        userId: { in: filtered.map((u) => u.id) },
        poll: { topicId: { in: criteria.topic_ids } },
      },
      select: { userId: true },
      distinct: ["userId"],
    });
    const interested = new Set(ids.map((v) => v.userId));
    filtered = filtered.filter((u) => interested.has(u.id));
  }

  // Breakdown
  const byGender: Record<string, number> = {};
  const byAge: Record<string, number> = {};
  const byCity: Record<string, number> = {};
  for (const u of filtered) {
    byGender[u.gender] = (byGender[u.gender] ?? 0) + 1;
    const ag = ageGroupForUser(u.birthYear);
    byAge[ag] = (byAge[ag] ?? 0) + 1;
    if (u.city) byCity[u.city] = (byCity[u.city] ?? 0) + 1;
  }

  const total = filtered.length;
  const discount = TIER_DISCOUNT[publisherTier] ?? 0;
  const perResponse = BASE_PER_RESPONSE * (1 - discount);
  const totalPrice = total * perResponse;

  // Representativeness vs national: compare to total respondent base.
  const national = await prisma.user.count({ where: { role: "respondent" } });
  const ratio = national > 0 ? Math.min(100, Math.round((total / national) * 100)) : 0;

  return {
    available_count: total,
    estimated_price_sar: Number(totalPrice.toFixed(2)),
    per_response_price_sar: Number(perResponse.toFixed(2)),
    median_response_minutes: total > 1000 ? 18 : total > 200 ? 60 : 240,
    representativeness: ratio,
    breakdown: {
      by_gender: byGender,
      by_age_group: byAge,
      by_city: byCity,
    },
  };
}

export async function listPublisherAudiences(publisherId: string) {
  return prisma.audience.findMany({
    where: { publisherId },
    orderBy: { createdAt: "desc" },
  });
}

export async function createAudience(
  publisherId: string,
  body: { name: string; criteria: AudienceCriteria; publisherTier?: string },
) {
  const est = await estimateAudience(body.criteria, body.publisherTier ?? "free");
  return prisma.audience.create({
    data: {
      publisherId,
      name: body.name,
      criteria: body.criteria as unknown as Prisma.InputJsonValue,
      availableCount: est.available_count,
      estimatedPrice: est.estimated_price_sar,
      status: "draft",
    },
  });
}
