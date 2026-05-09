"use client";

import { use } from "react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { KPICard } from "@/components/KPICard";
import { QualityBadge } from "@/components/QualityBadge";
import { ChartCard } from "@/components/ChartCard";
import { Donut } from "@/components/charts/Donut";
import { HBar } from "@/components/charts/HBar";
import { GroupedBar } from "@/components/charts/GroupedBar";
import { StackedBar } from "@/components/charts/StackedBar";
import { AreaTrend } from "@/components/charts/Area";
import { Heatmap } from "@/components/charts/Heatmap";
import { fmtInt, fmtSeconds, fmtPctRaw, deviceLabel, genderLabel } from "@/lib/format";

const AGE_BUCKETS_ORDER = ["18-24", "25-34", "35-44", "45-54", "55+"];

export default function PollDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { token } = useAuth();
  const analytics = useFetch((t) => api.pollAnalytics(t, id), token, [id]);
  const bootstrap = useFetch((t) => api.bootstrap(t), token);

  const poll = bootstrap.data?.polls.find((p) => p.id === id);

  if (analytics.loading) {
    return (
      <>
        <Header title="بانتظار التحليل…" />
        <main className="px-9 py-6 grid gap-5 grid-cols-3">
          {[0, 1, 2, 3, 4, 5].map((i) => <div key={i} className="h-72 rounded-card shimmer" />)}
        </main>
      </>
    );
  }
  if (analytics.error || !analytics.data) {
    return (
      <>
        <Header title="خطأ" />
        <main className="px-9 py-8">
          <div className="bg-canvas-card rounded-card p-6 text-center text-danger">
            {analytics.error ?? "تعذّر جلب التحليل."}
          </div>
        </main>
      </>
    );
  }

  const a = analytics.data;
  const optionsForDonut = a.options.map((o) => ({ label: o.text, value: o.votes_count }));

  // Cities (HBar)
  const cities = Object.entries(a.breakdown.by_city_top).map(([label, value]) => ({ label, value }));

  // Devices (HBar)
  const devices = Object.entries(a.breakdown.by_device).map(([label, value]) => ({
    label: deviceLabel(label),
    value,
  }));

  // Grouped: option × age
  const groupedByAge = AGE_BUCKETS_ORDER.map((bucket) => {
    const row: Record<string, string | number> = { group: bucket };
    a.cross_demographic.forEach((cross, idx) => {
      const opt = a.options[idx];
      if (!opt) return;
      row[opt.text] = cross.by_age_group[bucket] ?? 0;
    });
    return row;
  });

  // Stacked: option × gender
  const stackedByGender = a.options.map((opt, idx) => {
    const cross = a.cross_demographic[idx];
    return {
      group: opt.text,
      ذكور:    cross?.by_gender.male ?? 0,
      إناث:    cross?.by_gender.female ?? 0,
      "غير محدد": cross?.by_gender.unspecified ?? 0,
    } as Record<string, string | number>;
  });

  // Area trend
  const trend = a.timeline.daily_cumulative.map((p) => ({ day: p.day.slice(5), value: p.cumulative_votes }));

  // Heatmap: hour × (day-of-week derived from votes — simplified to single day for the Beta)
  // For the in-process demo we group by hour only; the dashboard frame still
  // looks correct because the same shape will populate when day-of-week is added.
  const hourCells = Object.entries(a.timeline.by_hour_of_day).map(([hour, value]) => ({
    row: "اليوم",
    col: `${hour}h`,
    value,
  }));
  const hourCols = Array.from(new Set(hourCells.map((c) => c.col))).sort();

  return (
    <>
      <Header
        title={poll?.title ?? "تحليل الاستطلاع"}
        subtitle={poll?.description ?? "تحليل ديموغرافي وسلوكي كامل"}
      />

      <main className="flex-1 px-9 py-6 space-y-6">
        {/* Quality + KPI strip */}
        <QualityBadge
          sampleSize={a.sample_size}
          confidenceLevel={a.confidence_level}
          marginOfError={a.margin_of_error}
          representativenessScore={a.representativeness_score}
          dataFreshness={a.data_freshness}
          methodologyNote={a.methodology_note}
        />

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
          <KPICard
            label="إجمالي الأصوات"
            value={fmtInt(a.sample_size)}
            hint={a.consensus.label}
            accent="brand"
          />
          <KPICard
            label="الخيار الرائد"
            value={fmtPctRaw(a.consensus.leading_percentage, 1)}
            hint={`فجوة استقطاب ${a.consensus.polarization_index.toFixed(1)}%`}
          />
          <KPICard
            label="متوسط القرار"
            value={fmtSeconds(a.behavioral.avg_decision_seconds)}
            hint={`نسبة تغيير الصوت ${a.behavioral.change_vote_rate_pct}%`}
            size="small"
          />
          <KPICard
            label="ساعة الذروة"
            value={a.timeline.peak_hour ? `${a.timeline.peak_hour}:00` : "—"}
            hint="بتوقيت UTC"
            size="small"
          />
        </div>

        {/* Row 1: Donut + Cities */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <ChartCard title="توزيع الخيارات" subtitle="نسبة كل خيار من إجمالي الأصوات">
            <Donut data={optionsForDonut} totalLabel="صوت" />
          </ChartCard>

          <ChartCard
            title="التوزيع الجغرافي"
            subtitle="أعلى المدن (الشرائط بنسبة لأكبر قيمة في الجدول)"
          >
            {cities.length > 0 ? <HBar data={cities} accent="#3CA597" /> : <Empty />}
          </ChartCard>
        </div>

        {/* Row 2: Grouped (age) + Stacked (gender) */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <ChartCard
            title="تفضيل الخيارات حسب الفئة العمرية"
            subtitle="أعمدة متراصّة تكشف فروقات الأجيال"
          >
            <GroupedBar data={groupedByAge} seriesKeys={a.options.map((o) => o.text)} />
          </ChartCard>

          <ChartCard
            title="تفضيل الخيارات حسب الجنس"
            subtitle="تركيب مكدّس يبيّن الحصة لكل خيار"
          >
            <StackedBar data={stackedByGender} seriesKeys={["ذكور", "إناث", "غير محدد"]} />
          </ChartCard>
        </div>

        {/* Row 3: Area + Devices */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
          <ChartCard
            className="lg:col-span-2"
            title="منحنى الأصوات التراكمي"
            subtitle="مع تظليل تدرّجي لقراءة الزخم"
            height={280}
          >
            {trend.length > 0 ? <AreaTrend data={trend} /> : <Empty />}
          </ChartCard>

          <ChartCard title="الأجهزة" subtitle="أيّ جهاز يصوّت من أين">
            {devices.length > 0 ? <HBar data={devices} accent="#8869C9" /> : <Empty />}
          </ChartCard>
        </div>

        {/* Row 4: Heatmap + Demographics donuts */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
          <ChartCard className="lg:col-span-2" title="الكثافة الزمنية" subtitle="عدد الأصوات حسب ساعة اليوم">
            {hourCells.length > 0 ? <Heatmap cells={hourCells} rowLabels={["اليوم"]} colLabels={hourCols} /> : <Empty />}
          </ChartCard>

          <ChartCard title="توزيع الجنس" subtitle="نسبة كل فئة من العيّنة">
            {Object.keys(a.breakdown.by_gender).length > 0 ? (
              <Donut
                data={Object.entries(a.breakdown.by_gender).map(([k, v]) => ({
                  label: genderLabel(k),
                  value: v,
                }))}
                totalLabel="مصوّت"
              />
            ) : (
              <Empty />
            )}
          </ChartCard>
        </div>

        {/* AI insight, if any */}
        {poll?.ai_insight && (
          <div className="bg-gradient-to-l from-brand-50/60 to-brand-50/20 border border-brand-100 rounded-card p-6">
            <div className="text-[10px] font-bold uppercase tracking-wider text-brand-600 mb-2">
              رؤية TRENDX AI
            </div>
            <p className="text-base text-ink leading-relaxed">{poll.ai_insight}</p>
          </div>
        )}
      </main>
    </>
  );
}

function Empty() {
  return (
    <div className="h-full grid place-items-center text-xs text-ink-mute">
      لا توجد بيانات كافية بعد لرسم هذه اللوحة.
    </div>
  );
}
