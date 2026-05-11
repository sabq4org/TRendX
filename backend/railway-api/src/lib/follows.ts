/**
 * Follow / unfollow helpers and the suggested-follows ranker.
 *
 * The follow table is authoritative; users.followers_count and
 * users.following_count mirror it for fast feed reads. Every mutation
 * runs inside a single transaction so the counters never drift.
 */

import { prisma } from "../db.js";

export async function followUser(followerId: string, followedId: string): Promise<{
  ok: boolean;
  already?: boolean;
  followersCount?: number;
}> {
  if (followerId === followedId) {
    throw Object.assign(new Error("لا يمكن متابعة حسابك."), { httpStatus: 400 });
  }

  // Pre-check via primary key — saves a transaction on the common
  // "already following" case.
  const existing = await prisma.userFollow.findUnique({
    where: { followerId_followedId: { followerId, followedId } },
  });
  if (existing) {
    const followed = await prisma.user.findUnique({
      where: { id: followedId },
      select: { followersCount: true },
    });
    return { ok: true, already: true, followersCount: followed?.followersCount };
  }

  const [, , followed] = await prisma.$transaction([
    prisma.userFollow.create({ data: { followerId, followedId } }),
    prisma.user.update({
      where: { id: followerId },
      data: { followingCount: { increment: 1 } },
    }),
    prisma.user.update({
      where: { id: followedId },
      data: { followersCount: { increment: 1 } },
    }),
  ]);

  return { ok: true, followersCount: followed.followersCount };
}

export async function unfollowUser(followerId: string, followedId: string): Promise<{
  ok: boolean;
  already?: boolean;
  followersCount?: number;
}> {
  const existing = await prisma.userFollow.findUnique({
    where: { followerId_followedId: { followerId, followedId } },
  });
  if (!existing) {
    const followed = await prisma.user.findUnique({
      where: { id: followedId },
      select: { followersCount: true },
    });
    return { ok: true, already: true, followersCount: followed?.followersCount };
  }

  const [, , followed] = await prisma.$transaction([
    prisma.userFollow.delete({
      where: { followerId_followedId: { followerId, followedId } },
    }),
    prisma.user.update({
      where: { id: followerId },
      data: { followingCount: { decrement: 1 } },
    }),
    prisma.user.update({
      where: { id: followedId },
      data: { followersCount: { decrement: 1 } },
    }),
  ]);

  return { ok: true, followersCount: followed.followersCount };
}

/**
 * Build a personalized list of accounts the user should follow.
 * Priority order:
 *  1. Verified accounts whose `topic` is in `followedTopics` (signal:
 *     they care about that sector).
 *  2. Government accounts (always surfaced — they're the highest-value
 *     accounts on the platform).
 *  3. Accounts in the user's city.
 *  4. Top organizations by `followersCount`.
 *
 * Already-followed accounts and the requesting user are filtered out.
 */
export async function suggestedFollows(userId: string, limit = 12) {
  const me = await prisma.user.findUnique({
    where: { id: userId },
    select: { followedTopics: true, city: true },
  });

  const alreadyFollowing = await prisma.userFollow.findMany({
    where: { followerId: userId },
    select: { followedId: true },
  });
  const excludeIds = new Set<string>([userId, ...alreadyFollowing.map((f) => f.followedId)]);

  // Pull a healthy candidate set then re-rank in JS — cleaner than a
  // 4-way UNION in SQL and the count is tiny.
  const [govs, verified, sameCity, popular] = await Promise.all([
    prisma.user.findMany({
      where: { accountType: "government", id: { notIn: [...excludeIds] } },
      orderBy: { followersCount: "desc" },
      take: 12,
    }),
    prisma.user.findMany({
      where: {
        isVerified: true,
        accountType: { not: "government" },
        id: { notIn: [...excludeIds] },
      },
      orderBy: { followersCount: "desc" },
      take: 24,
    }),
    me?.city
      ? prisma.user.findMany({
          where: {
            city: me.city,
            id: { notIn: [...excludeIds] },
            accountType: { not: "individual" },
          },
          orderBy: { followersCount: "desc" },
          take: 12,
        })
      : Promise.resolve([]),
    prisma.user.findMany({
      where: {
        accountType: { in: ["organization", "government"] },
        id: { notIn: [...excludeIds] },
      },
      orderBy: { followersCount: "desc" },
      take: 24,
    }),
  ]);

  // Rank: government > verified > sameCity > popular. De-dupe.
  const seen = new Set<string>();
  const pool: { score: number; user: (typeof govs)[number] }[] = [];
  for (const u of govs) {
    if (seen.has(u.id)) continue;
    seen.add(u.id);
    pool.push({ score: 1000 + u.followersCount, user: u });
  }
  for (const u of verified) {
    if (seen.has(u.id)) continue;
    seen.add(u.id);
    pool.push({ score: 600 + u.followersCount, user: u });
  }
  for (const u of sameCity) {
    if (seen.has(u.id)) continue;
    seen.add(u.id);
    pool.push({ score: 400 + u.followersCount, user: u });
  }
  for (const u of popular) {
    if (seen.has(u.id)) continue;
    seen.add(u.id);
    pool.push({ score: 100 + u.followersCount, user: u });
  }

  return pool
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((p) => p.user);
}

/**
 * Convenience: does `viewerId` follow `targetId`? Returns false when
 * `viewerId` is missing (anonymous).
 */
export async function viewerFollows(
  viewerId: string | null | undefined,
  targetId: string,
): Promise<boolean> {
  if (!viewerId || viewerId === targetId) return false;
  const row = await prisma.userFollow.findUnique({
    where: { followerId_followedId: { followerId: viewerId, followedId: targetId } },
    select: { followerId: true },
  });
  return row !== null;
}
