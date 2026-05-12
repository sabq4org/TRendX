/**
 * Lightweight per-key sliding-window rate limiter.
 *
 * Designed for the demo / beta workload: a single Railway instance,
 * thousands of users, and a handful of endpoints we want to protect
 * from a runaway client (or someone abusing a stolen token). State
 * lives in the process and resets on deploy — that's an acceptable
 * trade for not running Redis just for this.
 *
 * Usage from inside a Hono handler:
 *
 *     const key = c.get("userId");
 *     if (!rateLimit.allow(`${key}:vote`, 30, 60_000)) {
 *       return c.json({ error: "Too many requests" }, 429);
 *     }
 */

type Bucket = {
  // Monotonic timestamps (ms) of requests inside the window.
  hits: number[];
};

const buckets: Map<string, Bucket> = new Map();
let lastSweep = 0;
const SWEEP_INTERVAL_MS = 60_000; // garbage-collect idle keys every minute

function sweep(now: number) {
  if (now - lastSweep < SWEEP_INTERVAL_MS) return;
  lastSweep = now;
  // Drop buckets whose most recent hit is older than 5 minutes.
  const stale = now - 5 * 60 * 1000;
  for (const [key, bucket] of buckets) {
    if (bucket.hits.length === 0 || bucket.hits[bucket.hits.length - 1]! < stale) {
      buckets.delete(key);
    }
  }
}

/**
 * Returns true when the call is allowed. Returns false when the
 * caller has already made `max` requests inside the `windowMs`
 * window keyed on `key`.
 *
 * On allow, the call is recorded.
 *
 * The implementation uses a sliding window — when the window starts
 * is determined by the oldest still-valid hit, so a client can't
 * dodge the limit by aligning calls to a fixed boundary.
 */
export function allow(key: string, max: number, windowMs: number): boolean {
  const now = Date.now();
  sweep(now);

  const bucket = buckets.get(key) ?? { hits: [] };
  const cutoff = now - windowMs;

  // Trim hits that fell out of the window — kept inline to avoid an
  // extra pass and to keep the hot path branch-light.
  while (bucket.hits.length > 0 && bucket.hits[0]! < cutoff) {
    bucket.hits.shift();
  }

  if (bucket.hits.length >= max) {
    buckets.set(key, bucket);
    return false;
  }

  bucket.hits.push(now);
  buckets.set(key, bucket);
  return true;
}

export const rateLimit = { allow };
