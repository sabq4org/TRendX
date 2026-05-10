/**
 * Daily cron — runs once at boot (with a randomised delay so multiple
 * instances stagger) and once an hour afterwards. Each tick checks
 * whether the day has rolled over and runs:
 *
 *   1. Close yesterday's pulse + generate AI summary
 *   2. Create today's pulse (idempotent)
 *   3. Refresh TRENDX Index
 *   4. Open this week's challenge (idempotent)
 *
 * In-process is enough for our scale; we'll move to BullMQ when we
 * outgrow a single Railway instance.
 */

import { prisma } from "../db.js";
import {
  generatePulseAISummary,
  getOrCreateTodayPulse,
} from "../lib/pulse.js";
import { getCachedTrendXIndex } from "../lib/index-metrics.js";
import { getOrCreateThisWeekChallenge } from "../lib/challenges.js";

let timer: NodeJS.Timeout | null = null;
let lastRunDate: string | null = null;

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

async function tick(): Promise<void> {
  const today = todayIso();
  if (lastRunDate === today) return;
  lastRunDate = today;
  console.log(`[daily-cron] running for ${today}`);

  // 1. Close any pulses with status='active' whose date < today and
  //    generate their AI summary if missing.
  const stale = await prisma.dailyPulse.findMany({
    where: { status: "active", pulseDate: { lt: today } },
    select: { id: true, pulseDate: true },
    take: 20,
  });
  for (const s of stale) {
    try {
      await generatePulseAISummary(s.id);
      console.log(`[daily-cron] closed pulse ${s.pulseDate}`);
    } catch (err) {
      console.warn("[daily-cron] pulse summary failed:", err);
    }
  }

  // 2. Today's pulse
  try {
    await getOrCreateTodayPulse();
  } catch (err) {
    console.warn("[daily-cron] pulse creation failed:", err);
  }

  // 3. Refresh TRENDX Index (cached in ai_insights)
  try {
    await getCachedTrendXIndex(true);
  } catch (err) {
    console.warn("[daily-cron] index refresh failed:", err);
  }

  // 4. Weekly challenge
  try {
    await getOrCreateThisWeekChallenge();
  } catch (err) {
    console.warn("[daily-cron] challenge creation failed:", err);
  }
}

export function startDailyJob(): void {
  if (timer) return;
  // First run after 30s of boot, then every hour.
  setTimeout(() => {
    void tick();
    timer = setInterval(() => void tick(), 60 * 60 * 1000);
  }, 30_000);
}

export function stopDailyJob(): void {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
}
