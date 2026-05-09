/**
 * Periodic snapshot job. Runs every SNAPSHOT_INTERVAL_MIN (default 5)
 * inside the API process. Computes analytics for active polls + surveys
 * and stores them in `analytics_snapshots`.
 *
 * No Redis or BullMQ needed for the Beta — when concurrency outgrows a
 * single instance, this can be lifted into a dedicated worker by reusing
 * the same `computePollAnalytics` / `computeSurveyAnalytics` functions.
 */

import { prisma } from "../db.js";
import { computePollAnalytics, computeSurveyAnalytics } from "../lib/analytics.js";

let timer: NodeJS.Timeout | null = null;
let inFlight = false;

const INTERVAL_MIN = Number(process.env.SNAPSHOT_INTERVAL_MIN ?? "5");

async function runOnce(): Promise<void> {
  if (inFlight) {
    console.log("[snapshot] previous run still active, skipping.");
    return;
  }
  inFlight = true;
  const started = Date.now();
  try {
    const polls = await prisma.poll.findMany({
      where: { status: "active" },
      select: { id: true, title: true, totalVotes: true },
    });
    let pollUpdated = 0;
    for (const poll of polls) {
      if (poll.totalVotes === 0) continue; // skip empty polls
      const payload = await computePollAnalytics(poll.id);
      if (payload) {
        await prisma.analyticsSnapshot.create({
          data: {
            entityId: poll.id,
            entityType: "poll",
            payload: payload as unknown as object,
          },
        });
        pollUpdated += 1;
      }
    }

    const surveys = await prisma.survey.findMany({
      where: { status: "active" },
      select: { id: true, totalResponses: true },
    });
    let surveyUpdated = 0;
    for (const survey of surveys) {
      if (survey.totalResponses === 0) continue;
      const payload = await computeSurveyAnalytics(survey.id);
      if (payload) {
        await prisma.analyticsSnapshot.create({
          data: {
            entityId: survey.id,
            entityType: "survey",
            payload: payload as unknown as object,
          },
        });
        surveyUpdated += 1;
      }
    }

    // Light retention: keep the last 50 snapshots per entity to bound storage.
    await prisma.$executeRawUnsafe(`
      delete from analytics_snapshots
      where id in (
        select id from (
          select id, row_number() over (
            partition by entity_id, entity_type
            order by computed_at desc
          ) as rn
          from analytics_snapshots
        ) ranked
        where rn > 50
      )
    `);

    const elapsed = Date.now() - started;
    console.log(
      `[snapshot] ok: polls=${pollUpdated} surveys=${surveyUpdated} (${elapsed}ms)`,
    );
  } catch (error) {
    console.error("[snapshot] failed:", error);
  } finally {
    inFlight = false;
  }
}

export function startSnapshotJob(): void {
  if (timer) return;
  // Initial run after 30s warm-up so DB pool is ready.
  setTimeout(() => {
    void runOnce();
  }, 30_000);
  timer = setInterval(() => {
    void runOnce();
  }, INTERVAL_MIN * 60 * 1000);
  console.log(`[snapshot] scheduled every ${INTERVAL_MIN}min.`);
}

export function stopSnapshotJob(): void {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
}

export async function runSnapshotsNow(): Promise<void> {
  await runOnce();
}
