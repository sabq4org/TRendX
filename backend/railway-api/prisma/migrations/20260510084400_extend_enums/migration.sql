-- Extend InsightType + LedgerType enums.
-- Postgres requires `ALTER TYPE ... ADD VALUE` to run outside a
-- transaction, and the new value isn't usable in the same statement
-- block. Prisma migrate deploy honours this when the migration file
-- contains *only* enum DDL — keeping it in its own migration avoids
-- the "ALTER TYPE ... cannot run inside a transaction block" trap.

ALTER TYPE "InsightType" ADD VALUE IF NOT EXISTS 'user_dna';
ALTER TYPE "InsightType" ADD VALUE IF NOT EXISTS 'pulse_summary';
ALTER TYPE "InsightType" ADD VALUE IF NOT EXISTS 'trendx_index';
ALTER TYPE "InsightType" ADD VALUE IF NOT EXISTS 'audience_estimate';

ALTER TYPE "LedgerType" ADD VALUE IF NOT EXISTS 'challenge_winner';
ALTER TYPE "LedgerType" ADD VALUE IF NOT EXISTS 'pulse_streak_bonus';
