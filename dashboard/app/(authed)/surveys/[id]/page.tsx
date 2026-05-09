"use client";

import { use, useState } from "react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { KPICard } from "@/components/KPICard";
import { QualityBadge } from "@/components/QualityBadge";
import { ChartCard } from "@/components/ChartCard";
import { HBar } from "@/components/charts/HBar";
import { Donut } from "@/components/charts/Donut";
import { fmtInt, fmtSeconds, fmtPctRaw, deviceLabel, genderLabel } from "@/lib/format";
import clsx from "clsx";

const TABS = ["summary", "questions", "correlations", "ai"] as const;
type Tab = typeof TABS[number];

const TAB_LABELS: Record<Tab, string> = {
  summary: "ملخّص",
  questions: "الأسئلة",
  correlations: "الارتباطات",
  ai: "تقرير AI",
};

export default function SurveyDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { token } = useAuth();
  const analytics = useFetch((t) => api.surveyAnalytics(t, id), token, [id]);
  const survey = useFetch((t) => api.surveyDetail(t, id), token, [id]);
  const [tab, setTab] = useState<Tab>("summary");
  const [aiState, setAIState] = useState<{ loading: boolean; data: Awaited<ReturnType<typeof api.surveyAIReport>> | null; error: string | null }>(
    { loading: false, data: null, error: null },
  );

  async function generateAIReport() {
    if (!token || aiState.loading) return;
    setAIState((s) => ({ ...s, loading: true, error: null }));
    try {
      const data = await api.surveyAIReport(token, id);
      setAIState({ loading: false, data, error: null });
    } catch (err) {
      setAIState({
        loading: false,
        data: null,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }

  if (analytics.loading || survey.loading) {
    return (
      <>
        <Header title="بانتظار التحليل…" />
        <main className="px-9 py-6 grid gap-5 grid-cols-3">
          {[0, 1, 2, 3].map((i) => <div key={i} className="h-72 rounded-card shimmer" />)}
        </main>
      </>
    );
  }
  if (analytics.error || !analytics.data || !survey.data) {
    return (
      <>
        <Header title="خطأ" />
        <main className="px-9 py-8">
          <div className="bg-canvas-card rounded-card p-6 text-center text-danger">
            {analytics.error ?? "تعذّر جلب البيانات."}
          </div>
        </main>
      </>
    );
  }

  const a = analytics.data;
  const s = survey.data;

  return (
    <>
      <Header title={s.title} subtitle={s.description ?? "تحليل ذكاء استبياني كامل"} />

      <main className="flex-1 px-9 py-6 space-y-6">
        <QualityBadge
          sampleSize={a.sample_size}
          confidenceLevel={a.confidence_level}
          marginOfError={a.margin_of_error}
          representativenessScore={a.representativeness_score}
          dataFreshness={a.data_freshness}
          methodologyNote={a.methodology_note}
        />

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
          <KPICard label="مستجيبون" value={fmtInt(a.sample_size)} accent="brand" />
          <KPICard
            label="معدل الإكمال"
            value={fmtPctRaw(a.completion_rate, 0)}
            hint={`${fmtInt(a.funnel.completes)} من ${fmtInt(a.funnel.starts)}`}
          />
          <KPICard
            label="متوسط الإكمال"
            value={fmtSeconds(a.avg_completion_seconds)}
            size="small"
          />
          <KPICard
            label="ارتباطات قويّة"
            value={fmtInt(a.correlations.length)}
            hint="P ≥ 60% فقط"
            size="small"
          />
        </div>

        {/* Tab nav */}
        <div className="flex items-center gap-1.5 border-b border-ink-line -mb-px">
          {TABS.map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={clsx(
                "px-4 py-2.5 text-sm font-semibold transition rounded-t-chip",
                tab === t
                  ? "text-brand-600 bg-canvas-card border-b-2 border-brand-500"
                  : "text-ink-mute hover:text-ink",
              )}
            >
              {TAB_LABELS[t]}
            </button>
          ))}
        </div>

        {/* Tab content */}
        {tab === "summary" && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
            <ChartCard title="توزيع الجنس" subtitle="نسبة كل فئة">
              <Donut
                data={Object.entries(a.breakdown.by_gender).map(([k, v]) => ({
                  label: genderLabel(k), value: v,
                }))}
                totalLabel="مستجيب"
              />
            </ChartCard>

            <ChartCard title="الفئات العمرية" subtitle="توزيع الأعمار">
              <HBar
                data={Object.entries(a.breakdown.by_age_group)
                  .map(([k, v]) => ({ label: k, value: v }))
                  .sort((x, y) => y.value - x.value)}
                accent="#8869C9"
              />
            </ChartCard>

            <ChartCard title="الأجهزة" subtitle="نوع الجهاز المستخدم">
              <HBar
                data={Object.entries(a.breakdown.by_device).map(([k, v]) => ({
                  label: deviceLabel(k), value: v,
                }))}
                accent="#3CA597"
              />
            </ChartCard>

            <ChartCard
              title="أعلى المدن"
              subtitle="المراكز الحضرية الأكثر استجابة"
              className="lg:col-span-3"
            >
              <HBar
                data={Object.entries(a.breakdown.by_city_top).map(([k, v]) => ({
                  label: k, value: v,
                }))}
              />
            </ChartCard>
          </div>
        )}

        {tab === "questions" && (
          <div className="space-y-5">
            {a.per_question.map((q, idx) => (
              <div key={q.question_id} className="bg-canvas-card rounded-card shadow-card p-6">
                <div className="flex items-center justify-between mb-4 gap-4">
                  <div>
                    <div className="text-[10px] font-bold uppercase tracking-wide text-ink-mute mb-1">
                      السؤال {idx + 1}
                    </div>
                    <h3 className="text-base font-bold text-ink">{q.title}</h3>
                  </div>
                  <span
                    className={clsx(
                      "shrink-0 text-[10px] font-bold px-2.5 py-1 rounded-full",
                      q.consensus.label === "إجماع قوي" && "bg-success/10 text-success",
                      q.consensus.label === "ميل واضح" && "bg-brand-50 text-brand-700",
                      q.consensus.label === "اختلاف خفيف" && "bg-amber-50 text-amber-700",
                      q.consensus.label === "انقسام حاد" && "bg-danger/10 text-danger",
                    )}
                  >
                    {q.consensus.label}
                  </span>
                </div>

                <HBar
                  data={q.options.map((o) => ({
                    label: o.text,
                    value: o.votes_count,
                    subValue: `${o.percentage.toFixed(1)}%`,
                  }))}
                />

                <div className="mt-4 pt-4 border-t border-ink-line text-[11px] text-ink-mute flex items-center gap-4">
                  <span>متوسط الإجابة: {fmtSeconds(q.avg_seconds_to_answer)}</span>
                  <span>·</span>
                  <span>{fmtInt(q.sample_size)} مستجيب</span>
                </div>
              </div>
            ))}
          </div>
        )}

        {tab === "correlations" && (
          <div className="space-y-3">
            {a.correlations.length === 0 ? (
              <div className="bg-canvas-card rounded-card p-12 text-center text-ink-mute">
                لم تُكتشف ارتباطات قويّة (P ≥ 60%) بعد. زيادة العيّنة قد تكشف أنماطاً جديدة.
              </div>
            ) : (
              a.correlations.map((c, i) => (
                <div key={i} className="bg-canvas-card rounded-card shadow-card p-5">
                  <div className="flex items-start justify-between gap-4">
                    <div className="text-sm leading-relaxed">
                      <span className="text-ink-mute">من اختار</span>
                      <span className="font-bold text-ink mx-1">«{c.a1_text}»</span>
                      <span className="text-ink-mute">في سؤال</span>
                      <span className="text-ink mx-1 italic">«{c.q1_title.slice(0, 30)}…»</span>
                      <span className="text-ink-mute"> اختار أيضاً </span>
                      <span className="font-bold text-ink mx-1">«{c.a2_text}»</span>
                      <span className="text-ink-mute">في</span>
                      <span className="text-ink mx-1 italic">«{c.q2_title.slice(0, 30)}…»</span>
                    </div>
                    <span className="shrink-0 px-3 py-1 rounded-full bg-brand-50 text-brand-700 font-bold text-sm tabular">
                      {c.probability.toFixed(0)}%
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {tab === "ai" && (
          <div className="space-y-5">
            {!aiState.data && !aiState.loading && (
              <div className="bg-gradient-to-l from-brand-50/60 to-brand-50/20 border border-brand-100 rounded-card p-8 text-center">
                <h3 className="text-base font-bold text-ink mb-2">تقرير TRENDX AI الكامل</h3>
                <p className="text-sm text-ink-mute mb-5 max-w-md mx-auto leading-relaxed">
                  ملخّص تنفيذي + اكتشافات + شخصيات مكتشفة + أنماط خفية + توصيات استراتيجية مدعومة بـ GPT-4o.
                </p>
                <button
                  onClick={generateAIReport}
                  className="bg-brand-500 hover:bg-brand-600 text-white font-bold py-2.5 px-5 rounded-chip text-sm transition shadow-card"
                >
                  ✨ توليد التقرير الكامل
                </button>
                {aiState.error && (
                  <div className="mt-4 text-xs text-danger">{aiState.error}</div>
                )}
              </div>
            )}

            {aiState.loading && (
              <div className="bg-canvas-card rounded-card p-12 text-center">
                <div className="w-10 h-10 mx-auto rounded-full border-4 border-ink-line border-t-brand-500 animate-spin mb-3" />
                <p className="text-sm text-ink-mute">يتم توليد التقرير الكامل عبر GPT-4o…</p>
              </div>
            )}

            {aiState.data && (
              <>
                <div className="bg-canvas-card rounded-card shadow-card p-6">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-sm font-bold text-ink">الملخّص التنفيذي</h3>
                    <span className="text-[10px] text-ink-mute">
                      {aiState.data.model} · {aiState.data.prompt_version}
                    </span>
                  </div>
                  <p className="text-sm text-ink-soft leading-relaxed whitespace-pre-line">
                    {aiState.data.report.executive_summary}
                  </p>
                </div>

                <div className="bg-canvas-card rounded-card shadow-card p-6">
                  <h3 className="text-sm font-bold text-ink mb-4">الاكتشافات الرئيسية</h3>
                  <ul className="space-y-3">
                    {aiState.data.report.key_findings.map((f, i) => (
                      <li key={i} className="flex items-start gap-3">
                        <span className="shrink-0 w-6 h-6 rounded-full bg-brand-50 text-brand-700 text-xs font-bold grid place-items-center mt-0.5">
                          {i + 1}
                        </span>
                        <div className="flex-1">
                          <p className="text-sm text-ink leading-relaxed">{f.finding}</p>
                          <p className="text-[11px] text-ink-mute mt-1">{f.supporting_stat}</p>
                        </div>
                      </li>
                    ))}
                  </ul>
                </div>

                {aiState.data.report.persona_profiles.length > 0 && (
                  <div className="bg-canvas-card rounded-card shadow-card p-6">
                    <h3 className="text-sm font-bold text-ink mb-4">شخصيات المستجيبين</h3>
                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
                      {aiState.data.report.persona_profiles.map((p, i) => (
                        <div key={i} className="bg-canvas-well rounded-chip p-4">
                          <div className="flex items-center justify-between mb-3">
                            <div className="text-base font-bold text-ink">{p.name}</div>
                            <span className="text-sm font-bold tabular text-brand-600">{p.percent}%</span>
                          </div>
                          <div className="flex flex-wrap gap-1.5 mb-3">
                            {p.traits.map((t, j) => (
                              <span key={j} className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-canvas-card text-ink-soft border border-ink-line">
                                {t}
                              </span>
                            ))}
                          </div>
                          <p className="text-[12px] text-ink-soft italic leading-relaxed">
                            «{p.representative_quote}»
                          </p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {aiState.data.report.hidden_patterns.length > 0 && (
                  <div className="bg-canvas-card rounded-card shadow-card p-6">
                    <h3 className="text-sm font-bold text-ink mb-4">أنماط خفية</h3>
                    <ul className="space-y-3">
                      {aiState.data.report.hidden_patterns.map((p, i) => (
                        <li key={i} className="flex items-start gap-3 p-3 rounded-chip bg-canvas-well">
                          <span className="shrink-0 px-2.5 py-1 rounded-full bg-brand-50 text-brand-700 text-[11px] font-bold tabular">
                            {p.probability_pct.toFixed(0)}%
                          </span>
                          <div className="flex-1">
                            <p className="text-sm text-ink">{p.pattern}</p>
                            <p className="text-[11px] text-ink-mute mt-1">{p.implication}</p>
                          </div>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {aiState.data.report.strategic_recommendations.length > 0 && (
                  <div className="bg-canvas-card rounded-card shadow-card p-6">
                    <h3 className="text-sm font-bold text-ink mb-4">توصيات استراتيجية</h3>
                    <ul className="space-y-2.5">
                      {aiState.data.report.strategic_recommendations.map((r, i) => (
                        <li key={i} className="flex items-start gap-3 text-sm text-ink-soft leading-relaxed">
                          <span className="shrink-0 mt-1.5 w-1.5 h-1.5 rounded-full bg-brand-500" />
                          <span>{r}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                <div className="bg-canvas-card rounded-card shadow-card p-6">
                  <h3 className="text-sm font-bold text-ink mb-3">موقع الاستبيان في القطاع</h3>
                  <p className="text-sm text-ink-soft leading-relaxed">
                    {aiState.data.report.sector_position}
                  </p>
                </div>
              </>
            )}
          </div>
        )}
      </main>
    </>
  );
}
