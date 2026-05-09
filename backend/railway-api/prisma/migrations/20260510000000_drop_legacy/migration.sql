-- One-time cleanup: drop the pre-Prisma schema created by raw SQL migrations.
-- Safe on a fresh database (IF EXISTS) and on the Beta DB that still has
-- early test data.

DROP TABLE IF EXISTS "ai_events" CASCADE;
DROP TABLE IF EXISTS "redemptions" CASCADE;
DROP TABLE IF EXISTS "gifts" CASCADE;
DROP TABLE IF EXISTS "poll_votes" CASCADE;
DROP TABLE IF EXISTS "poll_options" CASCADE;
DROP TABLE IF EXISTS "polls" CASCADE;
DROP TABLE IF EXISTS "topics" CASCADE;
DROP TABLE IF EXISTS "profiles" CASCADE;
DROP TABLE IF EXISTS "beta_users" CASCADE;

-- Old uuid-ossp (replaced by Prisma's defaults using gen_random_uuid)
-- pgcrypto extension is created by the init migration if missing.
