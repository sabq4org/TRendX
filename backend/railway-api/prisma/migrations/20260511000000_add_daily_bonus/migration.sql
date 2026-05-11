-- Add `daily_bonus` to LedgerType so the /me/daily-bonus/claim endpoint
-- can record consecutive-day rewards alongside vote_reward, redemption,
-- pulse_streak_bonus, etc.

ALTER TYPE "LedgerType" ADD VALUE IF NOT EXISTS 'daily_bonus';
