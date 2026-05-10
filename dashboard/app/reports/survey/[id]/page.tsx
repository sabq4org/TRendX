"use client";

import { use, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { api } from "@/lib/api";
import { fmtInt, fmtPctRaw, fmtSeconds, genderLabel, deviceLabel } from "@/lib/format";
import type {
  Survey,
  SurveyAIReport,
  SurveyAnalytics,
  SurveyPersonas,
} from "@/lib/types";

/**
 * Print-ready report. Browser/Cmd+P or the dashboard's "Save as PDF" button
 * produce a clean A4 PDF. No sidebar, no auth UI — auth comes through ?token=.
 */
export default function SurveyPrintReport({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const searchParams = useSearchParams();
  const token = searchParams.get("token");

  const [survey, setSurvey] = useState<Survey | null>(null);
  const [analytics, setAnalytics] = useState<SurveyAnalytics | null>(null);
  const [aiReport, setAIReport] = useState<SurveyAIReport | null>(null);
  const [personas, setPersonas] = useState<SurveyPersonas | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) { setError("ينقص رمز المصادقة"); setLoading(false); return; }
    Promise.all([
      api.surveyDetail(token, id),
      api.surveyAnalytics(token, id),
      api.surveyAIReport(token, id).catch(() => null),
      api.surveyPersonas(token, id).catch(() => null),
    ])
      .then(([s, a, ai, p]) => {
        setSurvey(s);
        setAnalytics(a);
        setAIReport(ai);
        setPersonas(p);
      })
      .catch((err) => setError(err instanceof Error ? err.message : String(err)))
      .finally(() => setLoading(false));
  }, [id, token]);

  if (loading) {
    return (
      <main className="min-h-screen grid place-items-center">
        <div className="w-10 h-10 rounded-full border-2 border-ink-line border-t-brand-500 animate-spin" />
      </main>
    );
  }
  if (error || !survey || !analytics) {
    return (
      <main className="min-h-screen grid place-items-center p-12">
        <div className="text-center">
          <p className="text-negative font-bold">{error ?? "تعذّر تحميل التقرير"}</p>
        </div>
      </main>
    );
  }

  return (
    <main className="max-w-[820px] mx-auto px-12 py-10 print:px-8 print:py-6 leading-relaxed">
      <PrintControls />

      {/* Cover */}
      <section className="border-b-4 border-brand-500 pb-8 mb-10">
        <div className="text-[10px] font-bold uppercase tracking-[0.22em] text-brand-600 mb-3">
          TRENDX SURVEY INTELLIGENCE
        </div>
        <h1 className="text-4xl font-display font-black text-ink leading-tight tracking-tight mb-3">
          {survey.title}
        </h1>
        {survey.description && (
          <p className="text-base text-ink-soft font-light max-w-2xl">{survey.description}</p>
        )}
        <div className="grid grid-cols-4 gap-4 mt-8 text-center">
          <Cell label="مستجيبون" value={fmtInt(analytics.sample_size)} />
          <Cell label="إكمال" value={fmtPctRaw(analytics.completion_rate, 0)} />
          <Cell label="مستوى الثقة" value={`${analytics.confidence_level}%`} />
          <Cell label="هامش خطأ" value={analytics.margin_of_error !== null ? `±${analytics.margin_of_error}%` : "—"} />
        </div>
        <div className="text-[10px] text-ink-mute mt-6 font-mono">
          Generated {new Date().toLocaleString("en-US")} • TRENDX.app
        </div>
      </section>

      {/* Demographics */}
      <Section title="ملامح المستجيبين" eyebrow="DEMOGRAPHICS">
        <div className="grid grid-cols-2 gap-6">
          <SubSection title="الجنس">
            <BreakdownTable data={analytics.breakdown.by_gender} formatter={genderLabel} total={analytics.sample_size} />
          </SubSection>
          <SubSection title="الفئة العمريّة">
            <BreakdownTable data={analytics.breakdown.by_age_group} total={analytics.sample_size} />
          </SubSection>
          <SubSection title="الجهاز">
            <BreakdownTable data={analytics.breakdown.by_device} formatter={deviceLabel} total={analytics.sample_size} />
          </SubSection>
          <SubSection title="أعلى المدن">
            <BreakdownTable data={analytics.breakdown.by_city_top} total={analytics.sample_size} />
          </SubSection>
        </div>
      </Section>

      {/* Per-question */}
      <Section title="الأسئلة وتوزيعاتها" eyebrow="QUESTIONS">
        <ul className="space-y-6">
          {analytics.per_question.map((q, idx) => (
            <li key={q.question_id} className="pb-5 border-b border-ink-line/60 last:border-b-0">
              <div className="flex items-baseline justify-between gap-3 mb-3">
                <h3 className="text-base font-display font-bold text-ink">
                  <span className="text-brand-600 font-mono me-2">Q{String(idx + 1).padStart(2, "0")}</span>
                  {q.title}
                </h3>
                <span className="text-[10px] font-bold tabular text-ink-mute">{q.consensus.label}</span>
              </div>
              <ul className="space-y-1.5">
                {q.options.map((o) => (
                  <li key={o.id} className="flex items-center gap-3">
                    <span className="flex-1 text-[13px] text-ink-soft truncate">{o.text}</span>
                    <div className="w-32 h-2 bg-canvas-well rounded-pill overflow-hidden">
                      <div className="h-full bg-brand-500 rounded-pill" style={{ width: `${o.percentage}%` }} />
                    </div>
                    <span className="text-[12px] tabular text-ink font-bold w-12 text-end">{o.percentage.toFixed(1)}%</span>
                  </li>
                ))}
              </ul>
              <div className="text-[10px] text-ink-mute mt-3 font-mono">
                {fmtInt(q.sample_size)} مستجيب • متوسّط الإجابة {fmtSeconds(q.avg_seconds_to_answer)}
              </div>
            </li>
          ))}
        </ul>
      </Section>

      {/* Correlations */}
      {analytics.correlations.length > 0 && (
        <Section title="ارتباطات قويّة" eyebrow="CORRELATIONS (P ≥ 60%)">
          <ul className="space-y-3">
            {analytics.correlations.map((c, i) => (
              <li key={i} className="bg-canvas-well rounded-chip p-4 flex items-start justify-between gap-3 print:break-inside-avoid">
                <div className="text-[13px] leading-relaxed">
                  من اختار <strong>«{c.a1_text}»</strong> في «{c.q1_title.slice(0, 40)}»،
                  اختار أيضاً <strong className="text-brand-600">«{c.a2_text}»</strong> في «{c.q2_title.slice(0, 40)}»
                </div>
                <span className="shrink-0 text-base font-display font-black tabular text-brand-600">
                  {c.probability.toFixed(0)}%
                </span>
              </li>
            ))}
          </ul>
        </Section>
      )}

      {/* Personas */}
      {personas && personas.personas.length > 0 && (
        <Section title="الشخصيّات المكتشفة" eyebrow="PERSONAS">
          <div className="grid grid-cols-2 gap-4 print:grid-cols-1">
            {personas.personas.map((p) => (
              <article key={p.cluster_index} className="border border-ink-line/60 rounded-chip p-5 print:break-inside-avoid">
                <div className="flex items-baseline justify-between mb-2">
                  <h3 className="text-lg font-display font-black text-ink tracking-tight">{p.name}</h3>
                  <span className="text-2xl font-display font-black text-brand-600 tabular">{p.share_pct}%</span>
                </div>
                <p className="text-[12px] text-ink-soft leading-relaxed font-light mb-3">{p.description}</p>
                {p.traits.length > 0 && (
                  <div className="flex flex-wrap gap-1.5 mb-3">
                    {p.traits.map((t, j) => (
                      <span key={j} className="text-[10px] font-bold px-2 py-0.5 rounded-pill bg-brand-50 text-brand-600">
                        {t}
                      </span>
                    ))}
                  </div>
                )}
                {p.representative_quote && (
                  <blockquote className="border-s-2 border-brand-300 ps-3 text-[12px] italic text-ink-soft leading-relaxed">
                    «{p.representative_quote}»
                  </blockquote>
                )}
              </article>
            ))}
          </div>
        </Section>
      )}

      {/* AI Report */}
      {aiReport && (
        <Section title="التقرير التحليلي (TRENDX AI)" eyebrow="AI INTELLIGENCE">
          <div className="space-y-5 print:break-inside-avoid">
            <SubSection title="الملخّص التنفيذي">
              <p className="text-[13px] text-ink-soft leading-loose font-light whitespace-pre-line">
                {aiReport.report.executive_summary}
              </p>
            </SubSection>

            {aiReport.report.key_findings.length > 0 && (
              <SubSection title="اكتشافات رئيسية">
                <ol className="list-decimal list-inside space-y-2 marker:font-bold marker:text-brand-600">
                  {aiReport.report.key_findings.map((f, i) => (
                    <li key={i} className="text-[13px] text-ink leading-relaxed">
                      <span className="font-medium">{f.finding}</span>
                      <span className="block ms-5 text-[11px] text-ink-mute font-light mt-0.5">{f.supporting_stat}</span>
                    </li>
                  ))}
                </ol>
              </SubSection>
            )}

            {aiReport.report.hidden_patterns.length > 0 && (
              <SubSection title="أنماط خفيّة">
                <ul className="space-y-2">
                  {aiReport.report.hidden_patterns.map((p, i) => (
                    <li key={i} className="bg-accent-50/60 rounded-chip p-3 flex items-start gap-3">
                      <span className="text-[11px] font-bold tabular px-2 py-0.5 rounded-pill bg-accent-500 text-white shrink-0">
                        {p.probability_pct.toFixed(0)}%
                      </span>
                      <div className="text-[12px] leading-relaxed">
                        <p className="text-ink font-medium">{p.pattern}</p>
                        <p className="text-ink-mute mt-0.5 font-light">{p.implication}</p>
                      </div>
                    </li>
                  ))}
                </ul>
              </SubSection>
            )}

            {aiReport.report.strategic_recommendations.length > 0 && (
              <SubSection title="توصيات استراتيجية">
                <ul className="space-y-1.5">
                  {aiReport.report.strategic_recommendations.map((r, i) => (
                    <li key={i} className="text-[13px] text-ink-soft leading-relaxed flex gap-3">
                      <span className="shrink-0 mt-2 w-1.5 h-1.5 rounded-full bg-brand-500" />
                      <span>{r}</span>
                    </li>
                  ))}
                </ul>
              </SubSection>
            )}

            {aiReport.report.sector_position && (
              <SubSection title="موقع الاستبيان في القطاع">
                <p className="text-[13px] text-ink-soft leading-loose font-light">{aiReport.report.sector_position}</p>
              </SubSection>
            )}

            <p className="text-[10px] text-ink-mute font-mono pt-3 border-t border-ink-line/40">
              {aiReport.model} • {aiReport.prompt_version} • {new Date(aiReport.generated_at).toLocaleString("en-US")}
            </p>
          </div>
        </Section>
      )}

      {/* Methodology */}
      <Section title="منهجية القياس" eyebrow="METHODOLOGY" lastSection>
        <p className="text-[12px] text-ink-soft leading-relaxed font-light">
          {analytics.methodology_note}
        </p>
        <div className="grid grid-cols-2 gap-3 mt-4 text-[11px]">
          <Stat label="تمثيل العيّنة" value={`${analytics.representativeness_score}/100`} />
          <Stat label="آخر تحديث للبيانات" value={new Date(analytics.data_freshness).toLocaleString("en-US")} />
        </div>
      </Section>

      <footer className="mt-12 pt-6 border-t border-ink-line text-center text-[10px] text-ink-mute font-mono">
        © TRENDX {new Date().getFullYear()} — تقرير سرّي للناشر فقط
      </footer>
    </main>
  );
}

// ---- Subcomponents ----

function PrintControls() {
  return (
    <div className="print:hidden flex justify-end mb-6">
      <button
        onClick={() => window.print()}
        className="brand-fill font-bold py-2 px-5 rounded-chip text-sm shadow-card hover:shadow-glow transition"
      >
        طباعة / حفظ PDF
      </button>
    </div>
  );
}

function Section({
  title, eyebrow, children, lastSection,
}: { title: string; eyebrow: string; children: React.ReactNode; lastSection?: boolean }) {
  return (
    <section className={`mb-8 ${lastSection ? "" : "pb-8 border-b border-ink-line/60"} print:break-inside-avoid-page`}>
      <div className="text-[10px] font-bold uppercase tracking-[0.22em] text-brand-600 mb-2">{eyebrow}</div>
      <h2 className="text-2xl font-display font-black text-ink tracking-tight mb-5">{title}</h2>
      {children}
    </section>
  );
}

function SubSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="text-sm font-bold text-ink mb-2 tracking-tight">{title}</h3>
      {children}
    </div>
  );
}

function Cell({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-3xl font-display font-black tabular text-brand-600 leading-none tracking-tight">{value}</div>
      <div className="text-[10px] uppercase tracking-[0.14em] text-ink-mute mt-1">{label}</div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-canvas-well rounded-chip p-2.5">
      <div className="text-[9px] uppercase tracking-[0.14em] text-ink-mute font-bold">{label}</div>
      <div className="text-[13px] font-bold text-ink tabular mt-0.5">{value}</div>
    </div>
  );
}

function BreakdownTable({
  data, total, formatter,
}: { data: Record<string, number>; total: number; formatter?: (k: string) => string }) {
  const sorted = Object.entries(data).sort((a, b) => b[1] - a[1]);
  return (
    <ul className="space-y-1.5">
      {sorted.map(([k, v]) => {
        const pct = total > 0 ? (v / total) * 100 : 0;
        return (
          <li key={k} className="flex items-center gap-3 text-[12px]">
            <span className="flex-1 text-ink-soft truncate">{formatter ? formatter(k) : k}</span>
            <div className="w-24 h-1.5 bg-canvas-well rounded-pill overflow-hidden">
              <div className="h-full bg-brand-500 rounded-pill" style={{ width: `${pct}%` }} />
            </div>
            <span className="tabular text-ink font-bold w-12 text-end">{pct.toFixed(0)}%</span>
            <span className="tabular text-ink-mute w-10 text-end">{fmtInt(v)}</span>
          </li>
        );
      })}
    </ul>
  );
}
