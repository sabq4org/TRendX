-- Performance indexes uncovered by the comprehensive audit.
--
-- Each CREATE is IF NOT EXISTS so re-running the postdeploy migration
-- on an already-migrated database is a no-op. The DB does the analyze
-- in the background; new indexes don't take effect until the planner
-- picks them up.

-- 1. votes.user_id — used in every "fetch poll with this user's
--    vote" join (pollDTO, /me/timeline, /users/:id/posts, etc.).
--    Without it Postgres falls back to a sequential scan of the
--    votes table on every poll lookup; that cost grows linearly
--    with the number of polls returned.
CREATE INDEX IF NOT EXISTS "votes_user_id_idx" ON "votes" ("user_id");

-- 2. polls(publisher_id, status) — covers the hot path on the
--    user-posts and account-timeline endpoints, which always
--    filter both fields together.
CREATE INDEX IF NOT EXISTS "polls_publisher_status_idx"
    ON "polls" ("publisher_id", "status");

-- 3. polls(status, created_at) — used by the trending-polls source
--    backing the Live radar tab (status="active" ORDER BY created_at).
CREATE INDEX IF NOT EXISTS "polls_status_created_at_idx"
    ON "polls" ("status", "created_at" DESC);

-- 4. reposts.created_at — every repost query orders by createdAt
--    DESC to surface the latest first. Single-column index works
--    because the table is small per-user and order is global.
CREATE INDEX IF NOT EXISTS "reposts_created_at_idx"
    ON "reposts" ("created_at" DESC);

-- 5. polls.expires_at — recently-ended results query uses a range
--    on expires_at. Combined with status="ended" the planner uses
--    this index for fast bounded scans.
CREATE INDEX IF NOT EXISTS "polls_expires_at_idx"
    ON "polls" ("expires_at" DESC);
