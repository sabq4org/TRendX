-- TRENDX seed data — idempotent starter content for the Beta.

insert into topics (name, icon, color, followers_count, posts_count)
values
  ('اجتماعية', 'person.3.fill',                'blue',   45,  16),
  ('إعلام',    'newspaper.fill',               'purple', 84,  10),
  ('اقتصاد',   'chart.line.uptrend.xyaxis',    'green',  120, 25),
  ('رياضة',    'sportscourt.fill',             'orange', 200, 42),
  ('تقنية',    'cpu.fill',                     'blue',   156, 33),
  ('صحة',      'heart.fill',                   'red',    89,  18)
on conflict (name) do nothing;

-- gifts has no natural unique constraint, so guard with NOT EXISTS so
-- re-running the seed never creates duplicate rows.
insert into gifts (name, brand_name, category, points_required, value_in_riyal, is_available)
select v.name, v.brand_name, v.category, v.points_required, v.value_in_riyal, v.is_available
from (values
  ('قسيمة قهوة',  'Dose Cafe',     'مقاهي',   120, 20::numeric, true),
  ('بطاقة تسوق',  'TRENDX Market', 'تسوق',   240, 50::numeric, true),
  ('حلوى فاخرة',  'Sweet Box',     'حلويات', 180, 35::numeric, true)
) as v(name, brand_name, category, points_required, value_in_riyal, is_available)
where not exists (
  select 1 from gifts g
  where g.name = v.name and g.brand_name = v.brand_name
);
