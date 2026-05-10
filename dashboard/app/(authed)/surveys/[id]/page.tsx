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
import { Sparkles } from "lucide-react";
import type { SurveyAIReport } from "@/lib/types";

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
  const [aiState, setAIState] = useState<{ loading: boolean; data: SurveyAIReport | null; error: string | null }>(
    { loading: false, data: null, error: null },
  );

  async function generateAIReport() {
    if (!token || aiState.loading) return;
    setAIState((s) => ({ ...s, loading: true, error: null }));
    try {
      const data = await api.surveyAIReport(token, id);
      setAIState({ loading: false, data, error: null });
    } catch (err) {
      setAIState({ loading: false, data: null, error: err instanceof Error ? err.message : String(err) });
    }
  }

  if (analytics.loading || survey.loading) {
    return (
      <>
        <Header eyebrow="SURVEY INTELLIGENCE" title="بانتظار التحليل…" />
        <main className="px-10 pb-10 grid gap-6 grid-cols-3">
          {[0, 1, 2, 3].map((i) => <div key={i} className="h-72 rounded-card shimmer" />)}
        </main>
      </>
    );
  }
  if (analytics.error || !analytics.data || !survey.data) {
    return (
      <>
        <Header eyebrow="SURVEY INTELLIGENCE" title="خطأ" />
        <main className="px-10 pb-10">
          <div className="bg-canvas-card rounded-card p-8 text-center text-negative">
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
      <Header
        eyebrow="SURVEY INTELLIGENCE"
        title={s.title}
        subtitle={s.description ?? "تحليل ذكاء استبياني كامل"}
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
          <KPICard index={0} tone="sage" label="مستجيبون" value={fmtInt(a.sample_size)} />
          <KPICard
            index={1} tone="gold"
            label="معدل الإكمال"
            value={fmtPctRaw(a.completion_rate, 0)}
            hint={`${fmtInt(a.funnel.completes)} من ${fmtInt(a.funnel.starts)}`}
          />
          <KPICard
            index={2} tone="copper" size="small"
            label="متوسّط الإكمال"
            value={fmtSeconds(a.avg_completion_seconds)}
          />
          <KPICard
            index={3} tone="sage" size="small"
            label="ارتباطات قويّة"
            value={fmtInt(a.correlations.length)}
            hint="P ≥ 60% فقط"
          />
        </div>

        {/* Tabs */}
        <div className="flex items-center gap-1 border-b border-ink-line/60 -mb-px">
          {TABS.map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={clsx(
                "px-5 py-3 text-sm font-bold transition relative",
                tab === t
                  ? "text-sage-700"
                  : "text-ink-mute hover:text-ink",
              )}
            >
              {TAB_LABELS[t]}
              {tab === t && (
                <span className="absolute bottom-0 inset-x-0 h-[2px] bg-sage-700 rounded-pill" />
              )}
            </button>
          ))}
        </div>

        {tab === "summary" && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 stagger">
            <ChartCard eyebrow="GENDER" title="توزيع الجنس">
              <Donut
                data={Object.entries(a.breakdown.by_gender).map(([k, v]) => ({
                  label: genderLabel(k), value: v,
                }))}
                totalLabel="مستجيب"
              />
            </ChartCard>

            <ChartCard eyebrow="AGE" title="الفئات العمرية">
              <HBar
                data={Object.entries(a.breakdown.by_age_group)
                  .map(([k, v]) => ({ label: k, value: v }))
                  .sort((x, y) => y.value - x.value)}
                accent="#C9A961"
              />
            </ChartCard>

            <ChartCard eyebrow="DEVICES" title="الأجهزة">
              <HBar
                data={Object.entries(a.breakdown.by_device).map(([k, v]) => ({
                  label: deviceLabel(k), value: v,
                }))}
                accent="#B86F4A"
              />
            </ChartCard>

            <ChartCard
              className="lg:col-span-3"
              eyebrow="GEOGRAPHY"
              title="أعلى المدن"
              subtitle="المراكز الحضرية الأكثر استجابة"
            >
              <HBar
                data={Object.entries(a.breakdown.by_city_top).map(([k, v]) => ({ label: k, value: v }))}
                accent="#3F6B4D"
              />
            </ChartCard>
          </div>
        )}

        {tab === "questions" && (
          <div className="space-y-5 stagger">
            {a.per_question.map((q, idx) => (
              <div key={q.question_id} className="bg-canvas-card rounded-card shadow-card p-7">
                <div className="flex items-center justify-between mb-5 gap-4">
                  <div className="flex items-center gap-3">
                    <span className="text-[10px] font-mono font-bold tabular text-ink-mute">
                      Q{String(idx + 1).padStart(2, "0")}
                    </span>
                    <h3 className="text-lg font-display font-bold text-ink leading-snug">{q.title}</h3>
                  </div>
                  <span
                    className={clsx(
                      "shrink-0 text-[10px] font-bold px-3 py-1 rounded-pill",
                      q.consensus.label === "إجماع قوي" && "bg-positive-soft text-positive",
                      q.consensus.label === "ميل واضح" && "bg-sage-50 text-sage-700",
                      q.consensus.label === "اختلاف خفيف" && "bg-gold-50 text-gold-700",
                      q.consensus.label === "انقسام حاد" && "bg-negative-soft text-negative",
                    )}
                  >
                    {q.consensus.label}
                  </span>
                </div>

                <HBar
                  data={q.options.map((o) => ({
                    label: o.text, value: o.votes_count, subValue: `${o.percentage.toFixed(1)}%`,
                  }))}
                  accent="#3F6B4D"
                />

                <div className="mt-5 pt-5 border-t border-ink-line/40 text-[11px] text-ink-mute flex items-center gap-3">
                  <span>متوسّط الإجابة: {fmtSeconds(q.avg_seconds_to_answer)}</span>
                  <span>•</span>
                  <span>{fmtInt(q.sample_size)} مستجيب</span>
                </div>
              </div>
            ))}
          </div>
        )}

        {tab === "correlations" && (
          <div className="space-y-3 stagger">
            {a.correlations.length === 0 ? (
              <div className="bg-canvas-card rounded-card p-16 text-center text-ink-mute dotgrid">
                <p className="text-sm">لم تُكتشف ارتباطات قويّة (P ≥ 60%) بعد.</p>
                <p className="text-xs mt-1">زيادة العيّنة قد تكشف أنماطاً جديدة.</p>
              </div>
            ) : (
              a.correlations.map((c, i) => (
                <div key={i} className="bg-canvas-card rounded-card shadow-card p-6">
                  <div className="flex items-start justify-between gap-4">
                    <div className="text-[14px] leading-relaxed">
                      <span className="text-ink-mute">من اختار </span>
                      <span className="font-bold text-ink">«{c.a1_text}»</span>
                      <span className="text-ink-mute"> في </span>
                      <span className="text-ink italic">«{c.q1_title.slice(0, 30)}…»</span>
                      <span className="text-ink-mute"> اختار أيضاً </span>
                      <span className="font-bold text-sage-700">«{c.a2_text}»</span>
                      <span className="text-ink-mute"> في </span>
                      <span className="text-ink italic">«{c.q2_title.slice(0, 30)}…»</span>
                    </div>
                    <span className="shrink-0 px-3 py-1.5 rounded-pill bg-sage-700 text-canvas-card font-display font-black text-base tabular shadow-card">
                      {c.probability.toFixed(0)}%
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {tab === "ai" && (
          <div className="space-y-6 stagger">
            {!aiState.data && !aiState.loading && (
              <div className="bg-gold-50/40 border border-gold-100 rounded-card p-12 text-center">
                <Sparkles size={36} className="mx-auto text-gold-700 mb-4" />
                <h3 className="text-2xl font-display font-black text-ink mb-3 tracking-tight">
                  تقرير TRENDX AI الكامل
                </h3>
                <p className="text-[14px] text-ink-mute mb-7 max-w-md mx-auto leading-relaxed font-light">
                  ملخّص تنفيذي + اكتشافات + شخصيات مكتشفة + أنماط خفية + توصيات استراتيجية مدعومة بـ GPT-4o.
                </p>
                <button
                  onClick={generateAIReport}
                  className="bg-sage-700 hover:bg-sage-900 text-canvas-card font-bold py-3 px-7 rounded-chip text-sm transition shadow-card hover:shadow-card-lift inline-flex items-center gap-2"
                >
                  <Sparkles size={14} /> توليد التقرير الكامل
                </button>
                {aiState.error && (
                  <div className="mt-5 text-xs text-negative">{aiState.error}</div>
                )}
              </div>
            )}

            {aiState.loading && (
              <div className="bg-canvas-card rounded-card p-16 text-center">
                <div className="w-10 h-10 mx-auto rounded-full border-2 border-ink-line border-t-sage-600 animate-spin mb-4" />
                <p className="text-sm text-ink-mute">يتم توليد التقرير عبر GPT-4o…</p>
              </div>
            )}

            {aiState.data && (
              <>
                <div className="bg-canvas-card rounded-card shadow-card p-8">
                  <div className="flex items-center justify-between mb-5">
                    <div>
                      <div className="text-eyebrow text-sage-700 mb-1.5">EXECUTIVE SUMMARY</div>
                      <h3 className="text-xl font-display font-black text-ink tracking-tight">الملخّص التنفيذي</h3>
                    </div>
                    <span className="text-[10px] tabular text-ink-mute font-mono">
                      {aiState.data.model} • {aiState.data.prompt_version}
                    </span>
                  </div>
                  <p className="text-[15px] text-ink-soft leading-loose whitespace-pre-line font-light">
                    {aiState.data.report.executive_summary}
                  </p>
                </div>

                <div className="bg-canvas-card rounded-card shadow-card p-8">
                  <div className="text-eyebrow text-sage-700 mb-1.5">KEY FINDINGS</div>
                  <h3 className="text-xl font-display font-black text-ink mb-6 tracking-tight">الاكتشافات الرئيسية</h3>
                  <ul className="space-y-4">
                    {aiState.data.report.key_findings.map((f, i) => (
                      <li key={i} className="flex items-start gap-4">
                        <span className="shrink-0 w-9 h-9 rounded-chip bg-sage-50 text-sage-700 font-display font-black text-sm grid place-items-center mt-0.5">
                          {String(i + 1).padStart(2, "0")}
                        </span>
                        <div className="flex-1">
                          <p className="text-[15px] text-ink leading-relaxed font-medium">{f.finding}</p>
                          <p className="text-[12px] text-ink-mute mt-1.5 font-light">{f.supporting_stat}</p>
                        </div>
                      </li>
                    ))}
                  </ul>
                </div>

                {aiState.data.report.persona_profiles.length > 0 && (
                  <div className="bg-canvas-card rounded-card shadow-card p-8">
                    <div className="text-eyebrow text-sage-700 mb-1.5">PERSONAS</div>
                    <h3 className="text-xl font-display font-black text-ink mb-6 tracking-tight">شخصيات المستجيبين</h3>
                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
                      {aiState.data.report.persona_profiles.map((p, i) => (
                        <div key={i} className="bg-canvas-well rounded-chip p-5">
                          <div className="flex items-baseline justify-between mb-3">
                            <div className="font-display font-black text-lg text-ink tracking-tight">{p.name}</div>
                            <span className="font-display font-black tabular text-sage-700 text-2xl">
                              {p.percent}<span className="text-xs font-medium text-ink-mute">%</span>
                            </span>
                          </div>
                          <div className="flex flex-wrap gap-1.5 mb-4">
                            {p.traits.map((t, j) => (
                              <span key={j} className="text-[10px] font-bold px-2 py-1 rounded-pill bg-canvas-card text-ink-soft border border-ink-line/40">
                                {t}
                              </span>
                            ))}
                          </div>
                          <p className="text-[12px] text-ink-soft italic leading-relaxed font-light">
                            «{p.representative_quote}»
                          </p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {aiState.data.report.hidden_patterns.length > 0 && (
                  <div className="bg-canvas-card rounded-card shadow-card p-8">
                    <div className="text-eyebrow text-sage-700 mb-1.5">HIDDEN PATTERNS</div>
                    <h3 className="text-xl font-display font-black text-ink mb-6 tracking-tight">أنماط خفية</h3>
                    <ul className="space-y-3">
                      {aiState.data.report.hidden_patterns.map((p, i) => (
                        <li key={i} className="flex items-start gap-4 p-4 rounded-chip bg-canvas-well">
                          <span className="shrink-0 px-3 py-1.5 rounded-pill bg-gold-50 text-gold-700 text-[12px] font-bold tabular">
                            {p.probability_pct.toFixed(0)}%
                          </span>
                          <div className="flex-1">
                            <p className="text-[14px] text-ink font-medium leading-relaxed">{p.pattern}</p>
                            <p className="text-[12px] text-ink-mute mt-1.5 font-light">{p.implication}</p>
                          </div>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {aiState.data.report.strategic_recommendations.length > 0 && (
                  <div className="bg-canvas-card rounded-card shadow-card p-8">
                    <div className="text-eyebrow text-sage-700 mb-1.5">RECOMMENDATIONS</div>
                    <h3 className="text-xl font-display font-black text-ink mb-6 tracking-tight">توصيات استراتيجية</h3>
                    <ul className="space-y-3">
                      {aiState.data.report.strategic_recommendations.map((r, i) => (
                        <li key={i} className="flex items-start gap-3 text-[14px] text-ink-soft leading-relaxed">
                          <span className="shrink-0 mt-2 w-1.5 h-1.5 rounded-full bg-sage-600" />
                          <span>{r}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                <div className="bg-canvas-card rounded-card shadow-card p-8">
                  <div className="text-eyebrow text-sage-700 mb-1.5">SECTOR POSITION</div>
                  <h3 className="text-xl font-display font-black text-ink mb-4 tracking-tight">موقع الاستبيان في القطاع</h3>
                  <p className="text-[14px] text-ink-soft leading-loose font-light">
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
