-- Phase 0 of the social-graph rollout.
--
-- Adds:
--   * AccountType enum (individual | organization | government)
--   * users.account_type, is_verified, handle, bio, banner_url
--   * indexes on the new typed fields
--   * reserved_handles table seeded with critical Saudi government /
--     royal / city names so they can't be taken by a regular signup
--     before the rightful body claims them.
--
-- Everything is additive: existing rows default to individual /
-- unverified and have NULL handle/bio/banner_url so the migration is
-- safe to re-run.

-- 1) Enum
DO $$ BEGIN
  CREATE TYPE "AccountType" AS ENUM ('individual', 'organization', 'government');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2) Columns on users
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "account_type" "AccountType" NOT NULL DEFAULT 'individual',
  ADD COLUMN IF NOT EXISTS "is_verified"  BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "handle"       TEXT,
  ADD COLUMN IF NOT EXISTS "bio"          TEXT,
  ADD COLUMN IF NOT EXISTS "banner_url"   TEXT;

-- 3) Unique constraint on handle (case-sensitive — normalization is
--    performed application-side before INSERT/SELECT).
CREATE UNIQUE INDEX IF NOT EXISTS "users_handle_key" ON "users"("handle");

-- 4) Helpful indexes for queries that surface the new fields
CREATE INDEX IF NOT EXISTS "users_account_type_idx" ON "users"("account_type");
CREATE INDEX IF NOT EXISTS "users_is_verified_idx"  ON "users"("is_verified");

-- 5) Reserved handles table
CREATE TABLE IF NOT EXISTS "reserved_handles" (
  "handle"       TEXT PRIMARY KEY,
  "reason"       TEXT,
  "reserved_for" TEXT,
  "category"     TEXT,
  "created_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 6) Seed the reserved handles (idempotent — ON CONFLICT DO NOTHING).
INSERT INTO "reserved_handles" ("handle", "reserved_for", "category") VALUES
  -- TRENDX brand
  ('trendx',          'TRENDX Official',                    'trendx'),
  ('trendx_ai',       'TRENDX AI',                          'trendx'),
  ('admin',           'Reserved',                           'trendx'),
  ('support',         'Reserved',                           'trendx'),
  -- Government ministries
  ('moh',             'وزارة الصحة',                        'government'),
  ('moe',             'وزارة التعليم',                       'government'),
  ('mof',             'وزارة المالية',                      'government'),
  ('mci',             'وزارة التجارة',                      'government'),
  ('moc',             'وزارة الاتصالات وتقنية المعلومات',  'government'),
  ('moj',             'وزارة العدل',                        'government'),
  ('moi',             'وزارة الداخلية',                     'government'),
  ('mod',             'وزارة الدفاع',                       'government'),
  ('moenergy',        'وزارة الطاقة',                       'government'),
  ('momra',           'وزارة الشؤون البلدية والقروية',     'government'),
  ('moia',            'وزارة الإعلام',                      'government'),
  ('mohu',            'وزارة الإسكان',                      'government'),
  ('mohrsd',          'وزارة الموارد البشرية',             'government'),
  ('mosa',            'وزارة الشؤون الاجتماعية',           'government'),
  ('motourism',       'وزارة السياحة',                      'government'),
  ('mosport',         'وزارة الرياضة',                      'government'),
  ('moculture',       'وزارة الثقافة',                      'government'),
  ('moenv',           'وزارة البيئة والمياه والزراعة',     'government'),
  ('mohajj',          'وزارة الحج والعمرة',                'government'),
  ('motransport',     'وزارة النقل',                        'government'),
  ('mofa',            'وزارة الخارجية',                     'government'),
  ('moip',            'وزارة الصناعة والثروة المعدنية',    'government'),
  ('moih',            'وزارة الاستثمار',                    'government'),
  -- Royal & high-level
  ('royal_court',     'الديوان الملكي',                     'royal'),
  ('council_ministers','مجلس الوزراء',                     'royal'),
  -- Major cities
  ('riyadh',          'هيئة تطوير الرياض',                 'city'),
  ('jeddah',          'أمانة جدة',                          'city'),
  ('makkah',          'أمانة العاصمة المقدسة',             'city'),
  ('madinah',         'أمانة المدينة المنورة',             'city'),
  ('dammam',          'أمانة الشرقية',                      'city'),
  -- Major media
  ('saudipress',      'واس - وكالة الأنباء السعودية',      'media'),
  ('alarabiya',       'العربية',                            'media'),
  ('alekhbariya',     'الإخبارية',                          'media'),
  ('sabq',            'صحيفة سبق',                          'media'),
  ('okaz',            'صحيفة عكاظ',                         'media'),
  -- Strategic initiatives
  ('vision2030',      'رؤية المملكة 2030',                 'royal'),
  ('neom',            'نيوم',                               'organization'),
  ('redsea',          'البحر الأحمر',                       'organization'),
  ('qiddiya',         'القدية',                             'organization'),
  ('diriyah',         'الدرعية',                            'organization')
ON CONFLICT ("handle") DO NOTHING;
