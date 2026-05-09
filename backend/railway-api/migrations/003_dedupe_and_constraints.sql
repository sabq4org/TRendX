-- Cleanup: remove gifts that were duplicated by earlier non-idempotent seeds,
-- then add a unique constraint so future re-runs of the seed cannot duplicate.
-- Safe to run multiple times.

-- Keep the oldest row for each (name, brand_name) pair, drop the rest.
-- Uses NOT IN against a CTE — works even when redemptions reference one of
-- the duplicates (we keep the oldest, which is the one originally referenced).
with keepers as (
  select min(created_at) as keep_at, name, brand_name
  from gifts
  group by name, brand_name
)
delete from gifts g
using keepers k
where g.name = k.name
  and g.brand_name = k.brand_name
  and g.created_at <> k.keep_at;

-- Add the unique constraint only if it doesn't already exist.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'gifts_name_brand_unique'
  ) then
    alter table gifts add constraint gifts_name_brand_unique unique (name, brand_name);
  end if;
end $$;
