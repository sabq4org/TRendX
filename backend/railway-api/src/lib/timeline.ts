/**
 * Timeline aggregator.
 *
 * Pulls a chronological feed of `TimelineActivity` events for the
 * viewer: items published by accounts the viewer follows, items in
 * topics the viewer follows, public votes by followed accounts, and a
 * sprinkling of "story" / "trending" / "results" cards.
 *
 * The endpoint is cursor-paginated by `cutoff` timestamp. Each call
 * caps the per-source pull and the de-duped output, so even on a
 * heavy account we do at most ~5 indexed scans + an in-memory merge.
 */

import { prisma } from "../db.js";
import { pollDTO, surveyDTO, userDTO } from "./dto.js";

export type TimelineFilter = "all" | "accounts" | "sectors" | "results";

export type TimelineActivity =
  | {
      kind: "poll_published";
      id: string;
      occurred_at: string;
      source: "following" | "sector";
      publisher: ReturnType<typeof userDTO> | null;
      poll: ReturnType<typeof pollDTO>;
    }
  | {
      kind: "repost";
      id: string;
      occurred_at: string;
      reposter: ReturnType<typeof userDTO>;
      poll: ReturnType<typeof pollDTO>;
      caption: string | null;
    }
  | {
      kind: "survey_published";
      id: string;
      occurred_at: string;
      source: "following" | "sector";
      publisher: ReturnType<typeof userDTO> | null;
      survey: ReturnType<typeof surveyDTO>;
    }
  | {
      kind: "vote_cast";
      id: string;
      occurred_at: string;
      voter: ReturnType<typeof userDTO>;
      poll: ReturnType<typeof pollDTO>;
      choice: string;
    }
  | {
      kind: "sector_trending";
      id: string;
      occurred_at: string;
      topic_id: string;
      topic_name: string;
      poll: ReturnType<typeof pollDTO>;
      total_votes: number;
    }
  | {
      kind: "poll_results";
      id: string;
      occurred_at: string;
      poll: ReturnType<typeof pollDTO>;
      leader_text: string;
      leader_percentage: number;
    }
  | {
      kind: "story";
      id: string;
      occurred_at: string;
      story: {
        id: string;
        title: string;
        description: string | null;
        cover_image: string | null;
        cover_style: string | null;
        publisher: ReturnType<typeof userDTO> | null;
        item_count: number;
      };
    };

export async function buildTimeline(
  userId: string,
  options: { cutoff?: Date; filter?: TimelineFilter; limit?: number } = {},
): Promise<{ items: TimelineActivity[]; next_cutoff: string | null }> {
  const cutoff = options.cutoff ?? new Date();
  const limit = Math.min(40, Math.max(8, options.limit ?? 24));
  const filter = options.filter ?? "all";

  const [me, follows] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      select: { followedTopics: true },
    }),
    prisma.userFollow.findMany({
      where: { followerId: userId },
      select: { followedId: true },
    }),
  ]);
  const followedIds = follows.map((f) => f.followedId);
  const followedTopicIds = me?.followedTopics ?? [];

  // -- Source 1: polls published by followed accounts.
  const followedPolls = filter === "sectors" || filter === "results"
    ? []
    : followedIds.length === 0
    ? []
    : await prisma.poll.findMany({
        where: {
          publisherId: { in: followedIds },
          createdAt: { lt: cutoff },
        },
        include: {
          options: { orderBy: { displayOrder: "asc" } },
          votes: { where: { userId }, select: { userId: true, optionId: true } },
          topic: true,
          publisher: { select: { id: true, accountType: true, isVerified: true, handle: true, name: true, avatarUrl: true, avatarInitial: true, bio: true, bannerUrl: true, followersCount: true, followingCount: true, points: true, coins: true, role: true, tier: true, gender: true, birthYear: true, city: true, region: true, country: true, deviceType: true, osVersion: true, email: true, phone: true, isPremium: true, followedTopics: true, completedPolls: true, joinedAt: true, lastActiveAt: true, updatedAt: true } },
        },
        orderBy: { createdAt: "desc" },
        take: limit,
      });

  // -- Source 2: polls in followed topics (skip if already from followed
  //    accounts).
  const sectorPollIds = new Set(followedPolls.map((p) => p.id));
  const sectorPolls = filter === "accounts" || filter === "results"
    ? []
    : followedTopicIds.length === 0
    ? []
    : await prisma.poll.findMany({
        where: {
          topicId: { in: followedTopicIds },
          createdAt: { lt: cutoff },
          id: { notIn: [...sectorPollIds] },
        },
        include: {
          options: { orderBy: { displayOrder: "asc" } },
          votes: { where: { userId }, select: { userId: true, optionId: true } },
          topic: true,
          publisher: { select: { accountType: true, isVerified: true, handle: true } },
        },
        orderBy: { createdAt: "desc" },
        take: Math.floor(limit * 0.7),
      });

  // -- Source 3: surveys from followed accounts.
  const followedSurveys = filter !== "all" && filter !== "accounts"
    ? []
    : followedIds.length === 0
    ? []
    : await prisma.survey.findMany({
        where: {
          publisherId: { in: followedIds },
          createdAt: { lt: cutoff },
        },
        include: {
          questions: {
            orderBy: { displayOrder: "asc" },
            include: { options: { orderBy: { displayOrder: "asc" } } },
          },
          topic: true,
          publisher: { select: { accountType: true, isVerified: true, handle: true, name: true } },
        },
        orderBy: { createdAt: "desc" },
        take: Math.floor(limit * 0.5),
      });

  // -- Source 4a: reposts by followed accounts.
  const reposts = filter !== "all" && filter !== "accounts"
    ? []
    : followedIds.length === 0
    ? []
    : await prisma.repost.findMany({
        where: {
          userId: { in: followedIds },
          createdAt: { lt: cutoff },
        },
        include: {
          user: true,
          poll: {
            include: {
              options: { orderBy: { displayOrder: "asc" } },
              topic: true,
              publisher: { select: { accountType: true, isVerified: true, handle: true } },
              votes: { where: { userId }, select: { userId: true, optionId: true } },
            },
          },
        },
        orderBy: { createdAt: "desc" },
        take: Math.floor(limit * 0.5),
      });

  // -- Source 4: public votes by followed accounts.
  const publicVotes = filter !== "all" && filter !== "accounts"
    ? []
    : followedIds.length === 0
    ? []
    : await prisma.vote.findMany({
        where: {
          userId: { in: followedIds },
          isPublic: true,
          votedAt: { lt: cutoff },
        },
        include: {
          user: true,
          poll: {
            include: {
              options: { orderBy: { displayOrder: "asc" } },
              topic: true,
              publisher: { select: { accountType: true, isVerified: true, handle: true } },
              votes: { where: { userId }, select: { userId: true, optionId: true } },
            },
          },
          option: true,
        },
        orderBy: { votedAt: "desc" },
        take: Math.floor(limit * 0.6),
      });

  // -- Source 5: recently-settled polls (poll_results) — those that
  //    transitioned to "ended" with the user's follow graph.
  const recentlyEnded = filter !== "all" && filter !== "results"
    ? []
    : await prisma.poll.findMany({
        where: {
          status: "ended",
          expiresAt: { lt: cutoff, gt: new Date(cutoff.getTime() - 7 * 24 * 60 * 60 * 1000) },
          OR: [
            { publisherId: { in: followedIds.length ? followedIds : ["-"] } },
            { topicId: { in: followedTopicIds.length ? followedTopicIds : ["-"] } },
          ],
        },
        include: {
          options: { orderBy: { votesCount: "desc" } },
          votes: { where: { userId }, select: { userId: true, optionId: true } },
          topic: true,
          publisher: { select: { accountType: true, isVerified: true, handle: true } },
        },
        orderBy: { expiresAt: "desc" },
        take: 6,
      });

  // -- Source 6: featured stories (active, pinned by publisher OR featured).
  // Stories are editorial — they belong only in the "all" feed, not in
  // the "accounts" tab which is meant to be people-driven (polls,
  // surveys, votes, reposts from accounts you follow).
  const stories = filter !== "all"
    ? []
    : await prisma.story.findMany({
        where: {
          status: "active",
          OR: [
            { publisherId: { in: followedIds.length ? followedIds : ["-"] } },
            { isFeatured: true },
          ],
          createdAt: { lt: cutoff },
        },
        include: {
          publisher: true,
          _count: { select: { polls: true, surveys: true } },
        },
        orderBy: [{ isPinned: "desc" }, { createdAt: "desc" }],
        take: 4,
      });

  // -- Source 7: cold-start fallback. When the viewer has no follows and
  //    no followed topics the standard sources all return empty arrays
  //    and the "all" tab renders blank — which looks broken on a fresh
  //    install. Pull the most recently published active polls so the
  //    radar always has something to show. Other filters intentionally
  //    stay empty (the user can switch back to "الكل" to explore).
  const fallbackPolls = (filter === "all"
                         && followedIds.length === 0
                         && followedTopicIds.length === 0)
    ? await prisma.poll.findMany({
        where: { status: "active", createdAt: { lt: cutoff } },
        include: {
          options: { orderBy: { displayOrder: "asc" } },
          votes: { where: { userId }, select: { userId: true, optionId: true } },
          topic: true,
          publisher: { select: { accountType: true, isVerified: true, handle: true } },
        },
        orderBy: { createdAt: "desc" },
        take: Math.floor(limit * 0.7),
      })
    : [];

  // -- Merge + sort + cap.
  const items: TimelineActivity[] = [];

  for (const p of followedPolls) {
    items.push({
      kind: "poll_published",
      id: `poll:${p.id}`,
      occurred_at: p.createdAt.toISOString(),
      source: "following",
      publisher: p.publisher ? userDTO(p.publisher as never) : null,
      poll: pollDTO(p, { userId }),
    });
  }
  for (const p of sectorPolls) {
    items.push({
      kind: "poll_published",
      id: `poll:${p.id}`,
      occurred_at: p.createdAt.toISOString(),
      source: "sector",
      publisher: null,
      poll: pollDTO(p, { userId }),
    });
  }
  for (const s of followedSurveys) {
    items.push({
      kind: "survey_published",
      id: `survey:${s.id}`,
      occurred_at: s.createdAt.toISOString(),
      source: "following",
      publisher: null,
      survey: surveyDTO(s),
    });
  }
  for (const v of publicVotes) {
    items.push({
      kind: "vote_cast",
      id: `vote:${v.id}`,
      occurred_at: v.votedAt.toISOString(),
      voter: userDTO(v.user),
      poll: pollDTO(v.poll, { userId }),
      choice: v.option.text,
    });
  }
  for (const r of reposts) {
    items.push({
      kind: "repost",
      id: `repost:${r.userId}:${r.pollId}`,
      occurred_at: r.createdAt.toISOString(),
      reposter: userDTO(r.user),
      poll: pollDTO(r.poll, { userId }),
      caption: r.caption,
    });
  }
  for (const p of recentlyEnded) {
    const top = p.options[0];
    if (!top) continue;
    items.push({
      kind: "poll_results",
      id: `results:${p.id}`,
      occurred_at: p.expiresAt.toISOString(),
      poll: pollDTO(p, { userId }),
      leader_text: top.text,
      leader_percentage: p.totalVotes > 0
        ? Math.round((top.votesCount / p.totalVotes) * 100)
        : 0,
    });
  }
  for (const st of stories) {
    items.push({
      kind: "story",
      id: `story:${st.id}`,
      occurred_at: st.createdAt.toISOString(),
      story: {
        id: st.id,
        title: st.title,
        description: st.description,
        cover_image: st.coverImage,
        cover_style: st.coverStyle,
        publisher: st.publisher ? userDTO(st.publisher) : null,
        item_count: (st._count?.polls ?? 0) + (st._count?.surveys ?? 0),
      },
    });
  }
  for (const p of fallbackPolls) {
    items.push({
      kind: "poll_published",
      id: `poll:${p.id}`,
      occurred_at: p.createdAt.toISOString(),
      source: "sector",
      publisher: null,
      poll: pollDTO(p, { userId }),
    });
  }

  items.sort((a, b) => b.occurred_at.localeCompare(a.occurred_at));
  const sliced = items.slice(0, limit);
  const nextCutoff = sliced.length > 0
    ? sliced[sliced.length - 1].occurred_at
    : null;

  return { items: sliced, next_cutoff: nextCutoff };
}
