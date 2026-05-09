-- TRENDX Beta schema (Railway Postgres)
-- Idempotent — safe to run on every boot.

create extension if not exists "pgcrypto";

create table if not exists beta_users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  password_hash text not null,
  password_salt text not null,
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid primary key references beta_users(id) on delete cascade,
  name text not null,
  email text,
  avatar_initial text not null default 'م',
  points integer not null default 100 check (points >= 0),
  coins numeric(12, 2) not null default 16.67 check (coins >= 0),
  followed_topics uuid[] not null default '{}',
  completed_polls uuid[] not null default '{}',
  is_premium boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists topics (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text not null,
  color text not null default 'blue',
  followers_count integer not null default 0 check (followers_count >= 0),
  posts_count integer not null default 0 check (posts_count >= 0),
  created_at timestamptz not null default now()
);

create table if not exists polls (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 3 and 500),
  description text,
  image_url text,
  cover_style text,
  author_id uuid references profiles(id) on delete set null,
  author_name text not null,
  author_avatar text not null default 'م',
  author_is_verified boolean not null default false,
  topic_id uuid references topics(id) on delete set null,
  topic_name text,
  type text not null default 'اختيار واحد',
  status text not null default 'نشط',
  total_votes integer not null default 0 check (total_votes >= 0),
  reward_points integer not null default 50 check (reward_points >= 0),
  duration_days integer not null default 7 check (duration_days > 0),
  expires_at timestamptz not null,
  ai_insight text,
  shares_count integer not null default 0 check (shares_count >= 0),
  reposts_count integer not null default 0 check (reposts_count >= 0),
  created_at timestamptz not null default now()
);

create table if not exists poll_options (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references polls(id) on delete cascade,
  text text not null,
  votes_count integer not null default 0 check (votes_count >= 0),
  created_at timestamptz not null default now()
);

create table if not exists poll_votes (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references polls(id) on delete cascade,
  option_id uuid not null references poll_options(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (poll_id, user_id)
);

create table if not exists gifts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  brand_name text not null,
  brand_logo text not null default '',
  category text not null,
  points_required integer not null check (points_required > 0),
  value_in_riyal numeric(12, 2) not null check (value_in_riyal >= 0),
  image_url text,
  is_redeem_at_store boolean not null default true,
  is_available boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  gift_id uuid not null references gifts(id) on delete restrict,
  gift_name text not null,
  brand_name text not null,
  points_spent integer not null,
  value_in_riyal numeric(12, 2) not null,
  code text not null unique,
  redeemed_at timestamptz not null default now()
);

create table if not exists ai_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete set null,
  type text not null,
  input_summary text not null default '',
  output jsonb,
  status text not null default 'ok',
  latency_ms integer,
  created_at timestamptz not null default now()
);

create index if not exists polls_expires_at_idx on polls(expires_at);
create index if not exists polls_topic_id_idx on polls(topic_id);
create index if not exists poll_options_poll_id_idx on poll_options(poll_id);
create index if not exists poll_votes_poll_id_idx on poll_votes(poll_id);
create index if not exists redemptions_user_id_idx on redemptions(user_id);
