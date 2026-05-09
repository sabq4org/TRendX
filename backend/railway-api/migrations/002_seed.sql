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

insert into gifts (name, brand_name, category, points_required, value_in_riyal, is_available)
values
  ('قسيمة قهوة',  'Dose Cafe',     'مقاهي',   120, 20, true),
  ('بطاقة تسوق',  'TRENDX Market', 'تسوق',   240, 50, true),
  ('حلوى فاخرة',  'Sweet Box',     'حلويات', 180, 35, true)
on conflict do nothing;
