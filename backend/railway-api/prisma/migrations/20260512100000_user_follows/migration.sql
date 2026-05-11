-- Phase 2 of the social-graph rollout: one-way follow system.
--
-- Adds:
--   * users.followers_count / users.following_count (denormalized)
--   * user_follows(follower_id, followed_id, created_at)
--
-- The counts are kept in sync application-side inside a transaction —
-- both `follow` and `unfollow` handlers bump the counter alongside the
-- INSERT/DELETE on user_follows.

-- 1) Counters on users — additive, default 0 so existing rows are fine.
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "followers_count" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "following_count" INTEGER NOT NULL DEFAULT 0;

-- 2) Follow table.
CREATE TABLE IF NOT EXISTS "user_follows" (
  "follower_id" UUID NOT NULL,
  "followed_id" UUID NOT NULL,
  "created_at"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "user_follows_pkey" PRIMARY KEY ("follower_id", "followed_id"),
  CONSTRAINT "user_follows_follower_fk"
    FOREIGN KEY ("follower_id") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "user_follows_followed_fk"
    FOREIGN KEY ("followed_id") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "user_follows_followed_id_idx"
  ON "user_follows"("followed_id");
CREATE INDEX IF NOT EXISTS "user_follows_follower_id_idx"
  ON "user_follows"("follower_id");
