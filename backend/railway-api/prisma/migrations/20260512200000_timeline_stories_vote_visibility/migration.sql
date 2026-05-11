-- Phase 3 of the social-graph rollout: timeline + stories +
-- opt-in vote visibility.

-- 1) Vote.is_public — drives whether the vote appears in followers'
--    timelines. Default false (private), user opts in per vote.
ALTER TABLE "votes"
  ADD COLUMN IF NOT EXISTS "is_public" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS "votes_is_public_idx" ON "votes"("is_public");

-- 2) Stories — editorial collections published by an account.
CREATE TABLE IF NOT EXISTS "stories" (
  "id"           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "publisher_id" UUID NOT NULL,
  "title"        TEXT NOT NULL,
  "description"  TEXT,
  "cover_image"  TEXT,
  "cover_style"  TEXT,
  "is_pinned"    BOOLEAN NOT NULL DEFAULT false,
  "is_featured"  BOOLEAN NOT NULL DEFAULT false,
  "status"       TEXT NOT NULL DEFAULT 'active',
  "starts_at"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "ends_at"      TIMESTAMP(3),
  "created_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "stories_publisher_fk"
    FOREIGN KEY ("publisher_id") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "stories_publisher_id_idx" ON "stories"("publisher_id");
CREATE INDEX IF NOT EXISTS "stories_is_featured_idx"  ON "stories"("is_featured");
CREATE INDEX IF NOT EXISTS "stories_is_pinned_idx"    ON "stories"("is_pinned");

-- 3) Poll / Survey membership in stories.
ALTER TABLE "polls"
  ADD COLUMN IF NOT EXISTS "story_id"    UUID,
  ADD COLUMN IF NOT EXISTS "story_order" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "polls"
  DROP CONSTRAINT IF EXISTS "polls_story_fk",
  ADD CONSTRAINT "polls_story_fk"
    FOREIGN KEY ("story_id") REFERENCES "stories"("id") ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS "polls_story_id_idx" ON "polls"("story_id");

ALTER TABLE "surveys"
  ADD COLUMN IF NOT EXISTS "story_id"    UUID,
  ADD COLUMN IF NOT EXISTS "story_order" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "surveys"
  DROP CONSTRAINT IF EXISTS "surveys_story_fk",
  ADD CONSTRAINT "surveys_story_fk"
    FOREIGN KEY ("story_id") REFERENCES "stories"("id") ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS "surveys_story_id_idx" ON "surveys"("story_id");
