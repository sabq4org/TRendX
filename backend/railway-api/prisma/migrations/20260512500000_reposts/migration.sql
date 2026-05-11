-- Reposts (إعادة نشر). One repost per (user, poll) — composite PK
-- gives natural idempotency on toggle.

CREATE TABLE IF NOT EXISTS "reposts" (
  "user_id"   UUID NOT NULL,
  "poll_id"   UUID NOT NULL,
  "caption"   TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "reposts_pkey" PRIMARY KEY ("user_id", "poll_id"),
  CONSTRAINT "reposts_user_fk"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "reposts_poll_fk"
    FOREIGN KEY ("poll_id") REFERENCES "polls"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "reposts_poll_id_idx" ON "reposts"("poll_id");
CREATE INDEX IF NOT EXISTS "reposts_user_id_idx" ON "reposts"("user_id");
