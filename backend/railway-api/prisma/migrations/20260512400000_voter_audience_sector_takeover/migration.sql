-- Phase 5: Verified-only polls + Sector takeovers.

-- 1) Poll audience gate.
ALTER TABLE "polls"
  ADD COLUMN IF NOT EXISTS "voter_audience" TEXT NOT NULL DEFAULT 'public';

CREATE INDEX IF NOT EXISTS "polls_voter_audience_idx" ON "polls"("voter_audience");

-- 2) Sector takeovers — admin-pinned association between a verified
--    account and a topic.
CREATE TABLE IF NOT EXISTS "sector_takeovers" (
  "id"               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "topic_id"         UUID NOT NULL,
  "publisher_id"     UUID NOT NULL,
  "featured_poll_id" UUID,
  "starts_at"        TIMESTAMP(3) NOT NULL,
  "ends_at"          TIMESTAMP(3) NOT NULL,
  "status"           TEXT NOT NULL DEFAULT 'active',
  "created_at"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "sector_takeovers_topic_fk"
    FOREIGN KEY ("topic_id") REFERENCES "topics"("id") ON DELETE CASCADE,
  CONSTRAINT "sector_takeovers_publisher_fk"
    FOREIGN KEY ("publisher_id") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "sector_takeovers_topic_id_idx"     ON "sector_takeovers"("topic_id");
CREATE INDEX IF NOT EXISTS "sector_takeovers_publisher_id_idx" ON "sector_takeovers"("publisher_id");
CREATE INDEX IF NOT EXISTS "sector_takeovers_status_idx"       ON "sector_takeovers"("status");
