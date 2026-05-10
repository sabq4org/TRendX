/**
 * Webhook delivery — fire-and-forget HTTP POSTs to publisher-registered
 * URLs whenever an interesting event happens. Each delivery is signed
 * with HMAC-SHA256 so the receiver can verify authenticity.
 *
 * Architecture:
 *   - In-process queue (a plain array). Adequate for the current scale
 *     (Railway single instance). When we move to a multi-replica setup
 *     this will be swapped for BullMQ + Redis without changing callers.
 *   - Each job retries up to 3 times with exponential backoff (2s, 8s,
 *     32s). After 3 failures the webhook's `failureCount` is bumped;
 *     after 10 consecutive failures it auto-deactivates.
 *   - All deliveries are logged to `audit_log` so admins can see what
 *     fired when, and what the receiver responded.
 */

import { createHmac, randomBytes } from "node:crypto";
import { prisma } from "../db.js";

export type WebhookEventType =
  | "poll.published"
  | "poll.vote_cast"
  | "poll.vote_milestone"
  | "poll.ended"
  | "survey.published"
  | "survey.response"
  | "survey.completed"
  | "ai.report_ready"
  | "topic.followed";

type Job = {
  id: string;
  webhookId: string;
  url: string;
  secret: string;
  event: WebhookEventType;
  payload: Record<string, unknown>;
  attempt: number;
  publisherId: string;
};

const queue: Job[] = [];
let isFlushing = false;

function nextId(): string {
  return randomBytes(8).toString("hex");
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function sign(secret: string, body: string): string {
  return createHmac("sha256", secret).update(body).digest("hex");
}

export function generateWebhookSecret(): string {
  return `whsec_${randomBytes(24).toString("base64url")}`;
}

/**
 * Public API — call this from anywhere (vote, milestone, AI ready, etc.).
 * Looks up active webhooks subscribed to the event and fans them out.
 *
 * Always best-effort. NEVER blocks the caller. Errors swallowed and
 * logged so a misbehaving subscriber can't take down user-facing flow.
 */
export async function dispatchWebhookEvent(
  event: WebhookEventType,
  payload: Record<string, unknown>,
  scope?: { publisherId?: string; topicId?: string },
): Promise<void> {
  try {
    const webhooks = await prisma.webhook.findMany({
      where: {
        isActive: true,
        events: { has: event },
        ...(scope?.publisherId ? { publisherId: scope.publisherId } : {}),
      },
    });
    for (const wh of webhooks) {
      queue.push({
        id: nextId(),
        webhookId: wh.id,
        url: wh.url,
        secret: wh.secret,
        event,
        payload,
        attempt: 0,
        publisherId: wh.publisherId,
      });
    }
    if (!isFlushing) flush().catch((err) => {
      console.error("[webhooks] flush error:", err);
    });
  } catch (error) {
    console.error("[webhooks] dispatch failed:", error);
  }
}

async function flush(): Promise<void> {
  if (isFlushing) return;
  isFlushing = true;
  try {
    while (queue.length > 0) {
      const job = queue.shift();
      if (!job) break;
      await deliver(job);
    }
  } finally {
    isFlushing = false;
  }
}

const BACKOFF_MS = [2_000, 8_000, 32_000];

async function deliver(job: Job): Promise<void> {
  const body = JSON.stringify({
    id: job.id,
    event: job.event,
    timestamp: new Date().toISOString(),
    data: job.payload,
  });
  const signature = sign(job.secret, body);

  let status = 0;
  let responseBody = "";
  let ok = false;

  try {
    const response = await fetch(job.url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-TRENDX-Event": job.event,
        "X-TRENDX-Delivery": job.id,
        "X-TRENDX-Signature": `sha256=${signature}`,
        "User-Agent": "TRENDX-Webhook/1.0",
      },
      body,
      // Keep latency bounded — receivers should ack quickly
      signal: AbortSignal.timeout(8_000),
    });
    status = response.status;
    responseBody = (await response.text().catch(() => "")).slice(0, 240);
    ok = response.ok;
  } catch (error) {
    status = 0;
    responseBody = error instanceof Error ? error.message.slice(0, 240) : "unknown";
    ok = false;
  }

  // Log every attempt for admin transparency
  await prisma.auditLog
    .create({
      data: {
        actorId: job.publisherId,
        action: ok ? "webhook.delivered" : "webhook.failed",
        resourceType: "webhook",
        resourceId: job.webhookId,
        metadata: {
          event: job.event,
          delivery_id: job.id,
          status,
          response: responseBody,
          attempt: job.attempt + 1,
        },
      },
    })
    .catch(() => null);

  if (ok) {
    await prisma.webhook
      .update({
        where: { id: job.webhookId },
        data: { lastFiredAt: new Date(), failureCount: 0 },
      })
      .catch(() => null);
    return;
  }

  // Failure: retry with backoff up to 3 times, then mark on the row
  if (job.attempt < BACKOFF_MS.length) {
    const wait = BACKOFF_MS[job.attempt];
    setTimeout(() => {
      queue.push({ ...job, attempt: job.attempt + 1 });
      flush().catch(() => null);
    }, wait);
    return;
  }

  // Final failure
  await prisma.webhook
    .update({
      where: { id: job.webhookId },
      data: {
        failureCount: { increment: 1 },
      },
    })
    .catch(() => null);

  // Auto-deactivate after 10 consecutive final failures
  const updated = await prisma.webhook.findUnique({
    where: { id: job.webhookId },
    select: { failureCount: true },
  });
  if (updated && updated.failureCount >= 10) {
    await prisma.webhook
      .update({
        where: { id: job.webhookId },
        data: { isActive: false },
      })
      .catch(() => null);
    await prisma.auditLog
      .create({
        data: {
          actorId: job.publisherId,
          action: "webhook.auto_deactivated",
          resourceType: "webhook",
          resourceId: job.webhookId,
          metadata: { reason: "10 consecutive delivery failures" },
        },
      })
      .catch(() => null);
  }
}

/**
 * Manually fire a test event to a webhook URL. Used by the publisher
 * UI to verify the receiver before going live.
 */
export async function testWebhook(
  webhookId: string,
): Promise<{ ok: boolean; status: number; response: string }> {
  const wh = await prisma.webhook.findUnique({ where: { id: webhookId } });
  if (!wh) return { ok: false, status: 404, response: "webhook not found" };
  const job: Job = {
    id: nextId(),
    webhookId: wh.id,
    url: wh.url,
    secret: wh.secret,
    event: "poll.published",
    payload: {
      test: true,
      message: "TRENDX webhook test from publisher console",
    },
    attempt: 99, // skip retry path for test
    publisherId: wh.publisherId,
  };
  const body = JSON.stringify({
    id: job.id,
    event: job.event,
    timestamp: new Date().toISOString(),
    test: true,
    data: job.payload,
  });
  const signature = sign(job.secret, body);
  try {
    const response = await fetch(job.url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-TRENDX-Event": job.event,
        "X-TRENDX-Delivery": job.id,
        "X-TRENDX-Signature": `sha256=${signature}`,
        "X-TRENDX-Test": "true",
      },
      body,
      signal: AbortSignal.timeout(8_000),
    });
    const text = (await response.text().catch(() => "")).slice(0, 240);
    return { ok: response.ok, status: response.status, response: text };
  } catch (error) {
    return {
      ok: false,
      status: 0,
      response: error instanceof Error ? error.message : "unknown",
    };
  }
}

/** Verify an incoming signature in tests / docs. Re-exported for clarity. */
export function verifySignature(
  secret: string,
  body: string,
  signatureHeader: string,
): boolean {
  const expected = sign(secret, body);
  const actual = signatureHeader.replace(/^sha256=/, "");
  return expected.length === actual.length && expected === actual;
}

/** Sleep helper exported for tests. */
export const __test_only__ = { sleep };
