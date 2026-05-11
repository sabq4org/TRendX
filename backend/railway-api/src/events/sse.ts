/**
 * Lightweight Server-Sent Events bus. Each connected dashboard client gets
 * a streaming response and receives every broadcast event as it happens.
 *
 * Why SSE and not WebSockets:
 *  - Survives every CDN/proxy without sticky sessions.
 *  - Single-direction (server→client) is exactly what the publisher
 *    dashboard needs (live ticker, vote firehose, milestone alerts).
 *  - Trivial to scale horizontally with a Redis pub/sub bridge later.
 */

import type { Context } from "hono";
import { streamSSE } from "hono/streaming";

export type DashboardEvent =
  | { type: "vote_cast"; pollId: string; pollTitle: string; city: string | null; deviceType: string; total: number }
  | { type: "vote_milestone"; pollId: string; pollTitle: string; total: number; milestone: number }
  | { type: "survey_completed"; surveyId: string; surveyTitle: string; total: number }
  | { type: "snapshot_refreshed"; entityType: "poll" | "survey"; entityId: string }
  | { type: "pulse_response"; pulse_id: string; total: number; timestamp: string }
  | { type: "comment_posted"; pollId: string; commentId: string; total: number }
  | { type: "gift_redeemed"; giftId: string; giftName: string; brandName: string; pointsSpent: number; valueInRiyal: number };

type Subscriber = {
  id: string;
  send: (event: DashboardEvent) => void;
};

const subscribers = new Set<Subscriber>();

export function broadcastEvent(event: DashboardEvent): void {
  for (const sub of subscribers) {
    try {
      sub.send(event);
    } catch (error) {
      console.warn(`[sse] subscriber ${sub.id} failed:`, error);
      subscribers.delete(sub);
    }
  }
}

export async function sseHandler(c: Context): Promise<Response> {
  return streamSSE(c, async (stream) => {
    const id = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    let aborted = false;

    const subscriber: Subscriber = {
      id,
      send: (event) => {
        if (aborted) return;
        void stream.writeSSE({
          event: event.type,
          data: JSON.stringify(event),
        });
      },
    };
    subscribers.add(subscriber);

    await stream.writeSSE({
      event: "ready",
      data: JSON.stringify({ subscriberId: id, ts: Date.now() }),
    });

    // Heartbeat every 25s so reverse proxies don't kill the connection.
    const heartbeat = setInterval(() => {
      if (aborted) return;
      void stream.writeSSE({ event: "ping", data: String(Date.now()) });
    }, 25_000);

    stream.onAbort(() => {
      aborted = true;
      clearInterval(heartbeat);
      subscribers.delete(subscriber);
    });

    // Hold the stream open. streamSSE awaits this promise; resolving it
    // closes the connection, so we wait until the client disconnects.
    await new Promise<void>((resolve) => {
      const checkAbort = setInterval(() => {
        if (aborted) {
          clearInterval(checkAbort);
          resolve();
        }
      }, 5_000);
    });
  });
}
