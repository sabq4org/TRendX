-- Phase: نبض اليوم (Daily Pulse) + Audience Marketplace + Predictive Accuracy
-- + Weekly Challenge + الحوار (Comments) + Opinion DNA
-- All additive. No existing tables touched. Enum changes live in the
-- previous migration (20260510084400_extend_enums) so the values are
-- already committed and usable here.
--
-- IMPORTANT: this file is intentionally idempotent (IF NOT EXISTS / DO
-- blocks for FKs) because an earlier revision shipped with an inline
-- COMMIT/BEGIN that left a few of these tables half-created in some
-- environments. Running this migration twice must be a safe no-op.

-- =============================================================================
-- daily_pulses
-- =============================================================================
CREATE TABLE IF NOT EXISTS "daily_pulses" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "pulse_date" TEXT NOT NULL,
    "question" VARCHAR(500) NOT NULL,
    "description" TEXT,
    "options" JSONB NOT NULL,
    "topic_id" UUID,
    "status" TEXT NOT NULL DEFAULT 'active',
    "total_responses" INTEGER NOT NULL DEFAULT 0,
    "tallies" JSONB NOT NULL DEFAULT '[]',
    "ai_summary" TEXT,
    "reward_points" INTEGER NOT NULL DEFAULT 40,
    "closes_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "daily_pulses_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "daily_pulses_pulse_date_key" ON "daily_pulses"("pulse_date");
CREATE INDEX IF NOT EXISTS "daily_pulses_status_idx" ON "daily_pulses"("status");
CREATE INDEX IF NOT EXISTS "daily_pulses_pulse_date_idx" ON "daily_pulses"("pulse_date");
DO $$ BEGIN
  ALTER TABLE "daily_pulses"
    ADD CONSTRAINT "daily_pulses_topic_id_fkey" FOREIGN KEY ("topic_id") REFERENCES "topics"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =============================================================================
-- daily_pulse_responses
-- =============================================================================
CREATE TABLE IF NOT EXISTS "daily_pulse_responses" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "pulse_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "option_index" INTEGER NOT NULL,
    "predicted_pct" INTEGER,
    "device_type" "DeviceType" NOT NULL DEFAULT 'unknown',
    "city" TEXT,
    "region" TEXT,
    "country" TEXT,
    "gender" "Gender" NOT NULL DEFAULT 'unspecified',
    "age_group" TEXT,
    "responded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "daily_pulse_responses_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "daily_pulse_responses_pulse_id_user_id_key" ON "daily_pulse_responses"("pulse_id", "user_id");
CREATE INDEX IF NOT EXISTS "daily_pulse_responses_pulse_id_idx" ON "daily_pulse_responses"("pulse_id");
DO $$ BEGIN
  ALTER TABLE "daily_pulse_responses"
    ADD CONSTRAINT "daily_pulse_responses_pulse_id_fkey" FOREIGN KEY ("pulse_id") REFERENCES "daily_pulses"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "daily_pulse_responses"
    ADD CONSTRAINT "daily_pulse_responses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =============================================================================
-- user_streaks
-- =============================================================================
CREATE TABLE IF NOT EXISTS "user_streaks" (
    "user_id" UUID NOT NULL,
    "current_streak" INTEGER NOT NULL DEFAULT 0,
    "longest_streak" INTEGER NOT NULL DEFAULT 0,
    "last_pulse_date" TEXT,
    "total_pulses" INTEGER NOT NULL DEFAULT 0,
    "freezes_left" INTEGER NOT NULL DEFAULT 2,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "user_streaks_pkey" PRIMARY KEY ("user_id")
);
DO $$ BEGIN
  ALTER TABLE "user_streaks"
    ADD CONSTRAINT "user_streaks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =============================================================================
-- audiences
-- =============================================================================
CREATE TABLE IF NOT EXISTS "audiences" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "publisher_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "criteria" JSONB NOT NULL,
    "available_count" INTEGER NOT NULL DEFAULT 0,
    "estimated_price" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "poll_id" UUID,
    "survey_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "audiences_pkey" PRIMARY KEY ("id")
);
CREATE INDEX IF NOT EXISTS "audiences_publisher_id_idx" ON "audiences"("publisher_id");
DO $$ BEGIN
  ALTER TABLE "audiences"
    ADD CONSTRAINT "audiences_publisher_id_fkey" FOREIGN KEY ("publisher_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =============================================================================
-- vote_predictions
-- =============================================================================
CREATE TABLE IF NOT EXISTS "vote_predictions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "poll_id" UUID NOT NULL,
    "predicted_pct" INTEGER NOT NULL,
    "actual_pct" INTEGER,
    "distance" INTEGER,
    "accuracy" INTEGER,
    "predicted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "scored_at" TIMESTAMP(3),
    CONSTRAINT "vote_predictions_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "vote_predictions_poll_id_user_id_key" ON "vote_predictions"("poll_id", "user_id");
CREATE INDEX IF NOT EXISTS "vote_predictions_user_id_idx" ON "vote_predictions"("user_id");
DO $$ BEGIN
  ALTER TABLE "vote_predictions"
    ADD CONSTRAINT "vote_predictions_poll_id_fkey" FOREIGN KEY ("poll_id") REFERENCES "polls"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "vote_predictions"
    ADD CONSTRAINT "vote_predictions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =============================================================================
-- weekly_challenges + predictions
-- =============================================================================
CREATE TABLE IF NOT EXISTS "weekly_challenges" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "week_start" TEXT NOT NULL,
    "question" VARCHAR(500) NOT NULL,
    "description" TEXT,
    "metric_label" TEXT NOT NULL,
    "closes_at" TIMESTAMP(3) NOT NULL,
    "target_pct" INTEGER,
    "status" TEXT NOT NULL DEFAULT 'open',
    "reward_points" INTEGER NOT NULL DEFAULT 500,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "weekly_challenges_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "weekly_challenges_week_start_key" ON "weekly_challenges"("week_start");

CREATE TABLE IF NOT EXISTS "weekly_challenge_predictions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "challenge_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "predicted_pct" INTEGER NOT NULL,
    "distance" INTEGER,
    "rank" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "weekly_challenge_predictions_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "weekly_challenge_predictions_challenge_id_user_id_key" ON "weekly_challenge_predictions"("challenge_id", "user_id");
CREATE INDEX IF NOT EXISTS "weekly_challenge_predictions_challenge_id_idx" ON "weekly_challenge_predictions"("challenge_id");
DO $$ BEGIN
  ALTER TABLE "weekly_challenge_predictions"
    ADD CONSTRAINT "weekly_challenge_predictions_challenge_id_fkey" FOREIGN KEY ("challenge_id") REFERENCES "weekly_challenges"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "weekly_challenge_predictions"
    ADD CONSTRAINT "weekly_challenge_predictions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =============================================================================
-- poll_comments + votes (الحوار)
-- =============================================================================
CREATE TABLE IF NOT EXISTS "poll_comments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "poll_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "body" VARCHAR(800) NOT NULL,
    "score" INTEGER NOT NULL DEFAULT 0,
    "upvotes" INTEGER NOT NULL DEFAULT 0,
    "downvotes" INTEGER NOT NULL DEFAULT 0,
    "author_vote_option_id" UUID,
    "status" TEXT NOT NULL DEFAULT 'visible',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "poll_comments_pkey" PRIMARY KEY ("id")
);
CREATE INDEX IF NOT EXISTS "poll_comments_poll_id_idx" ON "poll_comments"("poll_id");
CREATE INDEX IF NOT EXISTS "poll_comments_user_id_idx" ON "poll_comments"("user_id");
DO $$ BEGIN
  ALTER TABLE "poll_comments"
    ADD CONSTRAINT "poll_comments_poll_id_fkey" FOREIGN KEY ("poll_id") REFERENCES "polls"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "poll_comments"
    ADD CONSTRAINT "poll_comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS "poll_comment_votes" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "comment_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "value" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "poll_comment_votes_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "poll_comment_votes_comment_id_user_id_key" ON "poll_comment_votes"("comment_id", "user_id");
DO $$ BEGIN
  ALTER TABLE "poll_comment_votes"
    ADD CONSTRAINT "poll_comment_votes_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "poll_comments"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE "poll_comment_votes"
    ADD CONSTRAINT "poll_comment_votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
