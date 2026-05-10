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
import { Sparkles } from "lucide-react";

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
        <Header eyebrow="POLL ANALYTICS" title="بانتظار التحليل…" />
        <main className="px-10 pb-10 grid gap-6 grid-cols-3">
          {[0, 1, 2, 3, 4, 5].map((i) => <div key={i} className="h-72 rounded-card shimmer" />)}
        </main>
      </>
    );
  }
  if (analytics.error || !analytics.data) {
    return (
      <>
        <Header eyebrow="POLL ANALYTICS" title="خطأ" />
        <main className="px-10 pb-10">
          <div className="bg-canvas-card rounded-card p-8 text-center text-negative">
            {analytics.error ?? "تعذّر جلب التحليل."}
          </div>
        </main>
      </>
    );
  }

  const a = analytics.data;
  const optionsForDonut = a.options.map((o) => ({ label: o.text, value: o.votes_count }));

  const cities = Object.entries(a.breakdown.by_city_top).map(([label, value]) => ({ label, value }));

  const devices = Object.entries(a.breakdown.by_device).map(([label, value]) => ({
    label: deviceLabel(label),
    value,
  }));

  const groupedByAge = AGE_BUCKETS_ORDER.map((bucket) => {
    const row: Record<string, string | number> = { group: bucket };
    a.cross_demographic.forEach((cross, idx) => {
      const opt = a.options[idx];
      if (!opt) return;
      row[opt.text] = cross.by_age_group[bucket] ?? 0;
    });
    return row;
  });

  const stackedByGender = a.options.map((opt, idx) => {
    const cross = a.cross_demographic[idx];
    return {
      group: opt.text,
      ذكور:    cross?.by_gender.male ?? 0,
      إناث:    cross?.by_gender.female ?? 0,
      "غير محدد": cross?.by_gender.unspecified ?? 0,
    } as Record<string, string | number>;
  });

  const trend = a.timeline.daily_cumulative.map((p) => ({ day: p.day.slice(5), value: p.cumulative_votes }));

  const hourCells = Object.entries(a.timeline.by_hour_of_day).map(([hour, value]) => ({
    row: "اليوم",
    col: `${hour}h`,
    value,
  }));
  const hourCols = Array.from(new Set(hourCells.map((c) => c.col))).sort();

  return (
    <>
      <Header
        eyebrow="POLL ANALYTICS"
        title={poll?.title ?? "تحليل الاستطلاع"}
        subtitle={poll?.description ?? "تحليل ديموغرافي وسلوكي كامل مع جودة العيّنة."}
      />

      <main className="flex-1 px-10 pb-10 space-y-7">
        <QualityBadge
          sampleSize={a.sample_size}
          confidenceLevel={a.confidence_level}
          marginOfError={a.margin_of_error}
          representativenessScore={a.representativeness_score}
          dataFreshness={a.data_freshness}
          methodologyNote={a.methodology_note}
        />

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-6 stagger">
          <KPICard
            index={0} tone="sage"
            label="إجمالي الأصوات"
            value={fmtInt(a.sample_size)}
            hint={a.consensus.label}
          />
          <KPICard
            index={1} tone="gold"
            label="الخيار الرائد"
            value={fmtPctRaw(a.consensus.leading_percentage, 1)}
            hint={`فجوة الاستقطاب ${a.consensus.polarization_index.toFixed(1)}%`}
          />
          <KPICard
            index={2} tone="copper"
            size="small"
            label="متوسّط القرار"
            value={fmtSeconds(a.behavioral.avg_decision_seconds)}
            hint={`نسبة تغيير الصوت ${a.behavioral.change_vote_rate_pct}%`}
          />
          <KPICard
            index={3} tone="sage"
            size="small"
            label="ساعة الذروة"
            value={a.timeline.peak_hour ? `${a.timeline.peak_hour}:00` : "—"}
            hint="بتوقيت UTC"
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 stagger">
          <ChartCard eyebrow="DISTRIBUTION" title="توزيع الخيارات" subtitle="نسبة كل خيار من إجمالي الأصوات">
            <Donut data={optionsForDonut} totalLabel="صوت" />
          </ChartCard>

          <ChartCard eyebrow="GEOGRAPHY" title="التوزيع الجغرافي" subtitle="أعلى المدن (نسبة لأكبر قيمة في الجدول)">
            {cities.length > 0 ? <HBar data={cities} accent="#3F6B4D" /> : <Empty />}
          </ChartCard>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 stagger">
          <ChartCard eyebrow="AGE × OPTION" title="تفضيل الخيارات حسب الفئة العمرية" subtitle="يكشف فروقات الأجيال">
            <GroupedBar data={groupedByAge} seriesKeys={a.options.map((o) => o.text)} />
          </ChartCard>

          <ChartCard eyebrow="GENDER × OPTION" title="تفضيل الخيارات حسب الجنس" subtitle="تركيب مكدّس لحصص كل خيار">
            <StackedBar data={stackedByGender} seriesKeys={["ذكور", "إناث", "غير محدد"]} />
          </ChartCard>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 stagger">
          <ChartCard
            className="lg:col-span-2"
            eyebrow="MOMENTUM"
            title="منحنى الأصوات التراكمي"
            subtitle="اقرأ زخم الانتشار عبر الأيام"
            height={280}
          >
            {trend.length > 0 ? <AreaTrend data={trend} /> : <Empty />}
          </ChartCard>

          <ChartCard eyebrow="DEVICES" title="الأجهزة" subtitle="من أيّ نظام يصوّت الجمهور">
            {devices.length > 0 ? <HBar data={devices} accent="#C9A961" /> : <Empty />}
          </ChartCard>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 stagger">
          <ChartCard className="lg:col-span-2" eyebrow="HEATMAP" title="الكثافة الزمنية" subtitle="عدد الأصوات حسب ساعة اليوم">
            {hourCells.length > 0 ? <Heatmap cells={hourCells} rowLabels={["اليوم"]} colLabels={hourCols} /> : <Empty />}
          </ChartCard>

          <ChartCard eyebrow="GENDER" title="توزيع الجنس" subtitle="نسبة كل فئة من العيّنة">
            {Object.keys(a.breakdown.by_gender).length > 0 ? (
              <Donut
                data={Object.entries(a.breakdown.by_gender).map(([k, v]) => ({
                  label: genderLabel(k), value: v,
                }))}
                totalLabel="مصوّت"
              />
            ) : (
              <Empty />
            )}
          </ChartCard>
        </div>

        {poll?.ai_insight && (
          <div className="bg-gold-50/40 border border-gold-100 rounded-card p-8">
            <div className="flex items-center gap-2 mb-3">
              <Sparkles size={14} className="text-gold-700" />
              <span className="text-eyebrow text-gold-700">TRENDX AI INSIGHT</span>
            </div>
            <p className="text-lg font-display font-light text-ink leading-relaxed">{poll.ai_insight}</p>
          </div>
        )}
      </main>
    </>
  );
}

function Empty() {
  return (
    <div className="h-full grid place-items-center text-[12px] text-ink-mute dotgrid rounded-chip">
      لا توجد بيانات كافية بعد.
    </div>
  );
}
