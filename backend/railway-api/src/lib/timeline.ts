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
      /// Per-region winner snapshot — up to 5 regions with the
      /// option that came first for each. Empty when the poll is
      /// too small or demographics are sparse, in which case the
      /// iOS card simply omits the regional strip.
      regional_breakdown: Array<{
        region: string;
        leader_text: string;
        leader_percentage: number;
        total_votes: number;
      }>;
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
  options: {
    cutoff?: Date;
    filter?: TimelineFilter;
    limit?: number;
    topicId?: string;
  } = {},
): Promise<{ items: TimelineActivity[]; next_cutoff: string | null }> {
  const cutoff = options.cutoff ?? new Date();
  const limit = Math.min(40, Math.max(8, options.limit ?? 24));
  const filter = options.filter ?? "all";
  const focusedTopicId = options.topicId; // only honored when filter === "sectors"

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
  //
  // Shown in the Live ("all") and My-Network ("accounts") tabs. The
  // Sectors and Results tabs intentionally skip this source — they're
  // topic-scoped and outcome-scoped respectively.
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

  const seenPollIds = new Set(followedPolls.map((p) => p.id));

  // -- Source 2: sector polls.
  //
  // Drives the "القطاعات" tab. Behavior matrix:
  //   - filter === "sectors"   → show all sector polls. If a specific
  //                              topic is focused via `topicId`, scope
  //                              to that one; otherwise return polls
  //                              across every topic. Does NOT require
  //                              the viewer to follow any topic.
  //   - filter === "all"       → only polls in topics the viewer
  //                              follows, as a complement to followed
  //                              accounts.
  //   - filter === "accounts"  → skip — Accounts is people-scoped.
  //   - filter === "results"   → skip — Results is outcome-scoped.
  const sectorPolls =
    filter === "accounts" || filter === "results"
      ? []
      : filter === "sectors"
      ? await prisma.poll.findMany({
          where: {
            status: "active",
            createdAt: { lt: cutoff },
            id: { notIn: [...seenPollIds] },
            ...(focusedTopicId
              ? { topicId: focusedTopicId }
              : { topicId: { not: null } }),
          },
          include: {
            options: { orderBy: { displayOrder: "asc" } },
            votes: { where: { userId }, select: { userId: true, optionId: true } },
            topic: true,
            publisher: { select: { accountType: true, isVerified: true, handle: true, avatarUrl: true } },
          },
          orderBy: [{ totalVotes: "desc" }, { createdAt: "desc" }],
          take: limit,
        })
      : followedTopicIds.length === 0
      ? []
      : await prisma.poll.findMany({
          where: {
            topicId: { in: followedTopicIds },
            createdAt: { lt: cutoff },
            id: { notIn: [...seenPollIds] },
          },
          include: {
            options: { orderBy: { displayOrder: "asc" } },
            votes: { where: { userId }, select: { userId: true, optionId: true } },
            topic: true,
            publisher: { select: { accountType: true, isVerified: true, handle: true, avatarUrl: true } },
          },
          orderBy: { createdAt: "desc" },
          take: Math.floor(limit * 0.7),
        });
  for (const p of sectorPolls) seenPollIds.add(p.id);

  // -- Source 2b: trending polls across the whole network.
  //
  // The backbone of the Live ("all") tab. These are the most-engaged
  // active polls right now, regardless of whether the viewer follows
  // their publisher or topic. This is what turns the Live tab from a
  // "what your friends are doing" feed into a "what is الـ Saudi
  // Arabia voting on right now" feed — and what guarantees the screen
  // is never blank for a brand-new user.
  const trendingPolls = filter !== "all"
    ? []
    : await prisma.poll.findMany({
        where: {
          status: "active",
          createdAt: { lt: cutoff },
          id: { notIn: [...seenPollIds] },
        },
        include: {
          options: { orderBy: { displayOrder: "asc" } },
          votes: { where: { userId }, select: { userId: true, optionId: true } },
          topic: true,
          publisher: { select: { accountType: true, isVerified: true, handle: true, avatarUrl: true } },
        },
        orderBy: [{ totalVotes: "desc" }, { createdAt: "desc" }],
        take: Math.floor(limit * 0.7),
      });
  for (const p of trendingPolls) seenPollIds.add(p.id);

  // -- Source 3: surveys from followed accounts.
  //
  // We pull the *full* publisher record (same as followedPolls) so the
  // timeline activity card can render the Ministry of Media's actual
  // logo — `TimelinePublisher` on iOS needs `id`, `name`, `handle`,
  // `accountType`, `isVerified`, `avatarUrl`, `avatarInitial`. The
  // previous narrow Pick + `publisher: null` activity left the survey
  // card with a generic initial-circle for every government account.
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
          publisher: { select: { id: true, accountType: true, isVerified: true, handle: true, name: true, avatarUrl: true, avatarInitial: true, bio: true, bannerUrl: true, followersCount: true, followingCount: true, points: true, coins: true, role: true, tier: true, gender: true, birthYear: true, city: true, region: true, country: true, deviceType: true, osVersion: true, email: true, phone: true, isPremium: true, followedTopics: true, completedPolls: true, joinedAt: true, lastActiveAt: true, updatedAt: true } },
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
              publisher: { select: { accountType: true, isVerified: true, handle: true, avatarUrl: true } },
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
              publisher: { select: { accountType: true, isVerified: true, handle: true, avatarUrl: true } },
              votes: { where: { userId }, select: { userId: true, optionId: true } },
            },
          },
          option: true,
        },
        orderBy: { votedAt: "desc" },
        take: Math.floor(limit * 0.6),
      });

  // -- Source 5: recently-settled polls (poll_results).
  //
  // Drives the "النتائج" tab. The earlier version of this query
  // required the result to come from a followed account OR followed
  // topic, which made the tab empty for fresh users. The Results tab
  // is a Kingdom-wide retrospective — it should always show what
  // Saudi Arabia recently decided, regardless of who the viewer
  // follows. We still hold the 7-day window so it stays fresh.
  const recentlyEnded = filter !== "all" && filter !== "results"
    ? []
    : await prisma.poll.findMany({
        where: {
          status: "ended",
          expiresAt: { lt: cutoff, gt: new Date(cutoff.getTime() - 7 * 24 * 60 * 60 * 1000) },
        },
        include: {
          options: { orderBy: { votesCount: "desc" } },
          votes: { where: { userId }, select: { userId: true, optionId: true } },
          topic: true,
          publisher: { select: { accountType: true, isVerified: true, handle: true, avatarUrl: true } },
        },
        orderBy: [{ totalVotes: "desc" }, { expiresAt: "desc" }],
        take: filter === "results" ? 20 : 6,
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
  for (const p of trendingPolls) {
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
      publisher: s.publisher ? userDTO(s.publisher as never) : null,
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
  // Pre-compute regional breakdowns in one batched query keyed by
  // pollId. Done in a single groupBy instead of a per-poll loop so a
  // 20-result page costs one DB round-trip instead of 20.
  const endedIds = recentlyEnded.map((p) => p.id);
  const regionalRows = endedIds.length === 0
    ? []
    : await prisma.vote.groupBy({
        by: ["pollId", "region", "optionId"],
        where: { pollId: { in: endedIds }, region: { not: null } },
        _count: { _all: true },
      });

  // Build a poll-id → region → option-id → count map, then collapse
  // each region down to its winning option. Top 5 regions by total
  // vote volume are surfaced — anything beyond that and the card
  // strip becomes noise rather than insight.
  const regionalByPoll = new Map<
    string,
    Array<{
      region: string;
      leader_text: string;
      leader_percentage: number;
      total_votes: number;
    }>
  >();
  {
    const grouped: Record<string, Record<string, Record<string, number>>> = {};
    for (const row of regionalRows) {
      if (!row.region) continue;
      const pollMap = (grouped[row.pollId] ??= {});
      const regMap = (pollMap[row.region] ??= {});
      regMap[row.optionId] = (regMap[row.optionId] ?? 0) + row._count._all;
    }
    for (const p of recentlyEnded) {
      const pollMap = grouped[p.id];
      if (!pollMap) continue;
      const optionText = new Map(p.options.map((o) => [o.id, o.text]));
      const perRegion = Object.entries(pollMap)
        .map(([region, optMap]) => {
          let leaderId = "";
          let leaderCount = 0;
          let total = 0;
          for (const [optId, count] of Object.entries(optMap)) {
            total += count;
            if (count > leaderCount) { leaderCount = count; leaderId = optId; }
          }
          const leader = optionText.get(leaderId) ?? "—";
          const pct = total > 0 ? Math.round((leaderCount / total) * 100) : 0;
          return {
            region,
            leader_text: leader,
            leader_percentage: pct,
            total_votes: total,
          };
        })
        .sort((a, b) => b.total_votes - a.total_votes)
        .slice(0, 5);
      regionalByPoll.set(p.id, perRegion);
    }
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
      regional_breakdown: regionalByPoll.get(p.id) ?? [],
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
  items.sort((a, b) => b.occurred_at.localeCompare(a.occurred_at));
  const sliced = items.slice(0, limit);
  const nextCutoff = sliced.length > 0
    ? sliced[sliced.length - 1].occurred_at
    : null;

  return { items: sliced, next_cutoff: nextCutoff };
}
