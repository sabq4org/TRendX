/**
 * Smart notifications engine.
 *
 * Notifications are generated on-demand from the user's current state
 * rather than stored in a table. This keeps the system stateless during
 * the Beta — each `/notifications` request inspects:
 *   - the user's points balance vs cheapest affordable gift
 *   - active polls in topics they follow that are about to expire
 *   - whether they've answered today's Pulse
 *   - whether the weekly challenge is open and they haven't predicted
 *   - recent positive ledger entries to celebrate
 *
 * Persistence (read state, dismiss) is layered later — for now the iOS
 * client manages "read" locally in UserDefaults. The endpoint is fast
 * (a handful of indexed queries) so we can poll it.
 */

import { prisma } from "../db.js";
import { getOrCreateTodayPulse } from "./pulse.js";
import { getOrCreateThisWeekChallenge } from "./challenges.js";

export type NotificationKind =
  | "close_to_gift"
  | "expiring_poll"
  | "pulse_pending"
  | "challenge_open"
  | "reward_earned"
  | "streak_at_risk";

export type Notification = {
  id: string;
  kind: NotificationKind;
  title: string;
  body: string;
  icon: string;
  cta_label: string | null;
  cta_route: string | null;
  /** ISO-8601 timestamp the event the notification refers to occurred at. */
  occurred_at: string;
  /** Optional ID of an entity referenced by `cta_route`. */
  ref_id: string | null;
};

/**
 * Builds the user's current notification list — newest first, capped at 12.
 */
export async function buildNotifications(userId: string): Promise<Notification[]> {
  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

  const [user, gifts, ledgerEntries, todayPulse, challenge] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, points: true, name: true, followedTopics: true },
    }),
    prisma.gift.findMany({
      where: { isAvailable: true },
      orderBy: { pointsRequired: "asc" },
      take: 12,
    }),
    prisma.pointsLedger.findMany({
      where: { userId, amount: { gt: 0 }, createdAt: { gte: oneDayAgo } },
      orderBy: { createdAt: "desc" },
      take: 5,
    }),
    getOrCreateTodayPulse().catch(() => null),
    getOrCreateThisWeekChallenge().catch(() => null),
  ]);

  if (!user) return [];
  const followedTopicIds: string[] = user.followedTopics ?? [];

  const notifications: Notification[] = [];

  // 1. Close to gift — fire when 70%+ of the way to the cheapest affordable gift
  const reachable = gifts.find((g: { pointsRequired: number }) => g.pointsRequired > user.points)
    ?? gifts.find((g: { pointsRequired: number }) => g.pointsRequired >= user.points);
  if (reachable) {
    const remaining = Math.max(0, reachable.pointsRequired - user.points);
    const progress = reachable.pointsRequired > 0
      ? user.points / reachable.pointsRequired
      : 0;
    if (progress >= 0.7 && remaining > 0) {
      notifications.push({
        id: `close_to_gift_${reachable.id}`,
        kind: "close_to_gift",
        title: `قريب من ${reachable.brandName}`,
        body: `يبقى ${remaining} نقطة على هدية ${reachable.name} — شارك في استطلاع واحد وتقترب أكثر.`,
        icon: "gift.fill",
        cta_label: "افتح الهدايا",
        cta_route: "gifts",
        occurred_at: now.toISOString(),
        ref_id: reachable.id,
      });
    } else if (remaining === 0) {
      notifications.push({
        id: `gift_ready_${reachable.id}`,
        kind: "close_to_gift",
        title: `يمكنك استبدال ${reachable.brandName} الآن`,
        body: `لديك نقاط كافية لـ${reachable.name} — استبدلها قبل نفاذ الكمية.`,
        icon: "gift.fill",
        cta_label: "استبدل الآن",
        cta_route: "gifts",
        occurred_at: now.toISOString(),
        ref_id: reachable.id,
      });
    }
  }

  // 2. Pulse pending — daily nudge if they haven't answered today
  if (todayPulse) {
    const responded = await prisma.dailyPulseResponse.findUnique({
      where: { pulseId_userId: { pulseId: todayPulse.id, userId } },
    });
    if (!responded) {
      notifications.push({
        id: `pulse_${todayPulse.id}`,
        kind: "pulse_pending",
        title: "نبض اليوم بانتظارك",
        body: "صوّت في نبض اليوم وحافظ على سلسلتك — يستغرق 10 ثوانٍ.",
        icon: "waveform.path.ecg",
        cta_label: "صوّت الآن",
        cta_route: "pulse",
        occurred_at: now.toISOString(),
        ref_id: todayPulse.id,
      });
    }
  }

  // 3. Weekly challenge — if open and user hasn't predicted yet
  if (challenge && challenge.status === "open") {
    const myPrediction = await prisma.weeklyChallengePrediction.findUnique({
      where: { challengeId_userId: { challengeId: challenge.id, userId } },
    });
    if (!myPrediction) {
      const hoursLeft = Math.max(
        0,
        Math.round((challenge.closesAt.getTime() - now.getTime()) / 3_600_000),
      );
      notifications.push({
        id: `challenge_${challenge.id}`,
        kind: "challenge_open",
        title: "تحدّي هذا الأسبوع",
        body: hoursLeft > 24
          ? `${challenge.question} — توقّع واربح ${challenge.rewardPoints} نقطة.`
          : `ينتهي خلال ${hoursLeft} ساعة! توقّع الآن واربح ${challenge.rewardPoints} نقطة.`,
        icon: "target",
        cta_label: "شارك في التحدّي",
        cta_route: "challenge",
        occurred_at: challenge.weekStart,
        ref_id: challenge.id,
      });
    }
  }

  // 4. Expiring polls in followed topics
  if (followedTopicIds.length > 0) {
    const expiringSoon = await prisma.poll.findMany({
      where: {
        topicId: { in: followedTopicIds },
        status: "active",
        expiresAt: {
          gt: now,
          lt: new Date(now.getTime() + 48 * 60 * 60 * 1000),
        },
        votes: { none: { userId } },
      },
      orderBy: { expiresAt: "asc" },
      take: 2,
      select: {
        id: true,
        title: true,
        rewardPoints: true,
        expiresAt: true,
        topic: { select: { name: true } },
      },
    });

    for (const poll of expiringSoon) {
      const hoursLeft = Math.max(
        0,
        Math.round((poll.expiresAt.getTime() - now.getTime()) / 3_600_000),
      );
      notifications.push({
        id: `expiring_${poll.id}`,
        kind: "expiring_poll",
        title: hoursLeft <= 12 ? "ينتهي قريباً!" : "استطلاع في موضوع تتابعه",
        body: `${poll.title} — ${hoursLeft} ساعة متبقية. +${poll.rewardPoints} نقطة.`,
        icon: "clock.fill",
        cta_label: "صوّت الآن",
        cta_route: `poll:${poll.id}`,
        occurred_at: now.toISOString(),
        ref_id: poll.id,
      });
    }
  }

  // 5. Reward earned — celebrate any positive ledger entries from the last day
  for (const entry of ledgerEntries) {
    notifications.push({
      id: `reward_${entry.id}`,
      kind: "reward_earned",
      title: `+${entry.amount} نقطة جديدة`,
      body: entry.description ?? "حصلت على نقاط جديدة من نشاطك في TRENDX.",
      icon: "sparkles",
      cta_label: "افتح المحفظة",
      cta_route: "gifts",
      occurred_at: entry.createdAt.toISOString(),
      ref_id: entry.id,
    });
  }

  // Sort newest-first by occurred_at and cap.
  notifications.sort((a, b) => b.occurred_at.localeCompare(a.occurred_at));
  return notifications.slice(0, 12);
}
