/**
 * Streak system — counts consecutive days a user has answered the
 * national daily pulse. The number is stored on `user_streaks` and
 * updated transactionally with each pulse response.
 *
 * Rules
 *  - Today's pulse counted? streak += 1
 *  - Yesterday missed?      streak resets to 1 (today still counts)
 *  - 2-day grace per month  ("freeze" — eats one missed day silently)
 */

import { prisma } from "../db.js";

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

function yesterdayIso(): string {
  return new Date(Date.now() - 86_400_000).toISOString().slice(0, 10);
}

function daysBetween(a: string, b: string): number {
  const aD = new Date(`${a}T00:00:00Z`).getTime();
  const bD = new Date(`${b}T00:00:00Z`).getTime();
  return Math.round((aD - bD) / 86_400_000);
}

export async function recordStreakHit(userId: string, pulseDate: string): Promise<{
  current_streak: number;
  longest_streak: number;
  total_pulses: number;
  freezes_left: number;
  is_personal_best: boolean;
  delta: "+1" | "kept" | "frozen" | "reset";
}> {
  const existing = await prisma.userStreak.findUnique({ where: { userId } });

  if (!existing) {
    const created = await prisma.userStreak.create({
      data: {
        userId,
        currentStreak: 1,
        longestStreak: 1,
        lastPulseDate: pulseDate,
        totalPulses: 1,
        freezesLeft: 2,
      },
    });
    return {
      current_streak: created.currentStreak,
      longest_streak: created.longestStreak,
      total_pulses: created.totalPulses,
      freezes_left: created.freezesLeft,
      is_personal_best: true,
      delta: "+1",
    };
  }

  // Already counted today — idempotent no-op.
  if (existing.lastPulseDate === pulseDate) {
    return {
      current_streak: existing.currentStreak,
      longest_streak: existing.longestStreak,
      total_pulses: existing.totalPulses,
      freezes_left: existing.freezesLeft,
      is_personal_best: false,
      delta: "kept",
    };
  }

  let nextStreak = existing.currentStreak;
  let nextFreezes = existing.freezesLeft;
  let delta: "+1" | "frozen" | "reset" = "+1";

  if (existing.lastPulseDate) {
    const gap = daysBetween(pulseDate, existing.lastPulseDate);
    if (gap === 1) {
      nextStreak += 1;
    } else if (gap === 2 && existing.freezesLeft > 0) {
      // One missed day, eat a freeze — streak continues.
      nextStreak += 1;
      nextFreezes = existing.freezesLeft - 1;
      delta = "frozen";
    } else {
      nextStreak = 1;
      delta = "reset";
    }
  } else {
    nextStreak = 1;
  }

  const isPersonalBest = nextStreak > existing.longestStreak;
  const updated = await prisma.userStreak.update({
    where: { userId },
    data: {
      currentStreak: nextStreak,
      longestStreak: Math.max(existing.longestStreak, nextStreak),
      lastPulseDate: pulseDate,
      totalPulses: existing.totalPulses + 1,
      freezesLeft: nextFreezes,
    },
  });

  return {
    current_streak: updated.currentStreak,
    longest_streak: updated.longestStreak,
    total_pulses: updated.totalPulses,
    freezes_left: updated.freezesLeft,
    is_personal_best: isPersonalBest,
    delta,
  };
}

export async function getStreak(userId: string): Promise<{
  current_streak: number;
  longest_streak: number;
  total_pulses: number;
  freezes_left: number;
  last_pulse_date: string | null;
  status: "active_today" | "active_yesterday" | "broken" | "never";
}> {
  const row = await prisma.userStreak.findUnique({ where: { userId } });
  if (!row) {
    return {
      current_streak: 0,
      longest_streak: 0,
      total_pulses: 0,
      freezes_left: 2,
      last_pulse_date: null,
      status: "never",
    };
  }
  const today = todayIso();
  const yesterday = yesterdayIso();
  const status: "active_today" | "active_yesterday" | "broken" | "never" =
    row.lastPulseDate === today ? "active_today" :
    row.lastPulseDate === yesterday ? "active_yesterday" :
    "broken";

  return {
    current_streak: status === "broken" ? 0 : row.currentStreak,
    longest_streak: row.longestStreak,
    total_pulses: row.totalPulses,
    freezes_left: row.freezesLeft,
    last_pulse_date: row.lastPulseDate,
    status,
  };
}
