-- Phase 4: Events feature.
--
-- Events are public happenings organized by an account (typically a
-- government body or organization). Each event aggregates RSVPs and
-- exposes a per-city breakdown for the iOS Saudi map.

CREATE TABLE IF NOT EXISTS "events" (
  "id"             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "publisher_id"   UUID NOT NULL,
  "title"          TEXT NOT NULL,
  "description"    TEXT,
  "banner_image"   TEXT,
  "category"       TEXT,
  "status"         TEXT NOT NULL DEFAULT 'upcoming',
  "starts_at"      TIMESTAMP(3) NOT NULL,
  "ends_at"        TIMESTAMP(3),
  "city"           TEXT,
  "venue"          TEXT,
  "lat"            DECIMAL(9,6),
  "lng"            DECIMAL(9,6),
  "rsvp_count"     INTEGER NOT NULL DEFAULT 0,
  "attending_count" INTEGER NOT NULL DEFAULT 0,
  "story_id"       UUID,
  "story_order"    INTEGER NOT NULL DEFAULT 0,
  "created_at"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "events_publisher_fk"
    FOREIGN KEY ("publisher_id") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "events_story_fk"
    FOREIGN KEY ("story_id") REFERENCES "stories"("id") ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS "events_publisher_id_idx" ON "events"("publisher_id");
CREATE INDEX IF NOT EXISTS "events_status_idx"       ON "events"("status");
CREATE INDEX IF NOT EXISTS "events_starts_at_idx"    ON "events"("starts_at");
CREATE INDEX IF NOT EXISTS "events_city_idx"         ON "events"("city");

CREATE TABLE IF NOT EXISTS "event_responses" (
  "id"         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "event_id"   UUID NOT NULL,
  "user_id"    UUID NOT NULL,
  "status"     TEXT NOT NULL,
  "city"       TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "event_responses_event_fk"
    FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE CASCADE,
  CONSTRAINT "event_responses_user_fk"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "event_responses_event_user_unique" UNIQUE ("event_id", "user_id")
);

CREATE INDEX IF NOT EXISTS "event_responses_event_id_idx" ON "event_responses"("event_id");
CREATE INDEX IF NOT EXISTS "event_responses_status_idx"   ON "event_responses"("status");
CREATE INDEX IF NOT EXISTS "event_responses_city_idx"     ON "event_responses"("city");
