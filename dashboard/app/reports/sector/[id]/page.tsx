"use client";

import { use, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { api } from "@/lib/api";
import { fmtInt } from "@/lib/format";
import type { SectorAIReport, SentimentTimeline, Topic } from "@/lib/types";

export default function SectorPrintReport({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const searchParams = useSearchParams();
  const token = searchParams.get("token");

  const [topic, setTopic] = useState<Topic | null>(null);
  const [aiReport, setAIReport] = useState<SectorAIReport | null>(null);
  const [timeline, setTimeline] = useState<SentimentTimeline | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) { setError("ينقص رمز المصادقة"); setLoading(false); return; }
    Promise.all([
      api.bootstrap(token).then((b) => b.topics.find((t) => t.id === id) ?? null),
      api.topicInsight(token, id).catch(() => null),
      api.topicSentimentTimeline(token, id, 30).catch(() => null),
    ])
      .then(([t, r, tl]) => {
        setTopic(t);
        setAIReport(r);
        setTimeline(tl);
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
  if (error || !topic) {
    return (
      <main className="min-h-screen grid place-items-center p-12">
        <p className="text-negative font-bold">{error ?? "تعذّر تحميل التقرير"}</p>
      </main>
    );
  }

  return (
    <main className="max-w-[820px] mx-auto px-12 py-10 print:px-8 print:py-6 leading-relaxed">
      <div className="print:hidden flex justify-end mb-6">
        <button
          onClick={() => window.print()}
          className="brand-fill font-bold py-2 px-5 rounded-chip text-sm shadow-card hover:shadow-glow transition"
        >
          طباعة / حفظ PDF
        </button>
      </div>

      <section className="border-b-4 border-brand-500 pb-8 mb-10">
        <div className="text-[10px] font-bold uppercase tracking-[0.22em] text-brand-600 mb-3">
          TRENDX SECTOR INTELLIGENCE
        </div>
        <h1 className="text-4xl font-display font-black text-ink leading-tight tracking-tight mb-2">
          قطاع — {topic.name}
        </h1>
        <p className="text-base text-ink-soft font-light">
          تقرير ذكاء قطاعي شامل من بيانات TRENDX السعودية.
        </p>
        <div className="text-[10px] text-ink-mute mt-6 font-mono">
          Generated {new Date().toLocaleString("en-US")} • TRENDX.app
        </div>
      </section>

      {timeline && (
        <section className="mb-8 pb-8 border-b border-ink-line/60 print:break-inside-avoid">
          <div className="text-[10px] font-bold uppercase tracking-[0.22em] text-brand-600 mb-2">SENTIMENT</div>
          <h2 className="text-2xl font-display font-black text-ink mb-4 tracking-tight">مزاج القطاع — آخر 30 يوماً</h2>
          <div className="grid grid-cols-3 gap-4">
            <Cell label="المؤشّر الحالي" value={timeline.current_score.toFixed(0)} />
            <Cell label="الاتجاه"
                  value={timeline.direction === "rising" ? "صاعد" : timeline.direction === "falling" ? "هابط" : "مستقرّ"} />
            <Cell label="Δ خلال 30 يوماً"
                  value={`${timeline.delta_30d > 0 ? "+" : ""}${timeline.delta_30d}`} />
          </div>
        </section>
      )}

      {aiReport && (
        <section className="mb-8 pb-8 border-b border-ink-line/60 print:break-inside-avoid">
          <div className="text-[10px] font-bold uppercase tracking-[0.22em] text-brand-600 mb-2">AI INTELLIGENCE</div>
          <h2 className="text-2xl font-display font-black text-ink mb-5 tracking-tight">التقرير القطاعي</h2>

          <div className="space-y-5">
            <SubSection title="الملخّص الاستراتيجي">
              <p className="text-[13px] text-ink-soft leading-loose font-light whitespace-pre-line">
                {aiReport.report.strategic_brief}
              </p>
            </SubSection>

            {aiReport.report.consensus_map.length > 0 && (
              <SubSection title="خريطة الإجماع">
                <ul className="space-y-2">
                  {aiReport.report.consensus_map.map((c, i) => (
                    <li key={i} className="flex items-center gap-3 text-[13px]">
                      <span className="flex-1 text-ink truncate">{c.question}</span>
                      <div className="w-32 h-2 bg-canvas-well rounded-pill overflow-hidden">
                        <div className="h-full bg-brand-500 rounded-pill" style={{ width: `${c.leading_pct}%` }} />
                      </div>
                      <span className="tabular text-ink font-bold w-14 text-end">{c.leading_pct.toFixed(0)}%</span>
                    </li>
                  ))}
                </ul>
              </SubSection>
            )}

            {aiReport.report.sector_persona.name && (
              <SubSection title="شخصيّة القطاع الغالبة">
                <div className="bg-canvas-well rounded-chip p-4">
                  <div className="flex items-baseline justify-between">
                    <h3 className="text-lg font-display font-black text-ink tracking-tight">{aiReport.report.sector_persona.name}</h3>
                    <span className="text-2xl font-display font-black text-brand-600 tabular">{aiReport.report.sector_persona.share_pct}%</span>
                  </div>
                  <p className="text-[12px] text-ink-soft font-light mt-2 leading-relaxed">
                    {aiReport.report.sector_persona.description}
                  </p>
                </div>
              </SubSection>
            )}

            {aiReport.report.cross_survey_patterns.length > 0 && (
              <SubSection title="أنماط مشتركة بين الاستبيانات">
                <ul className="space-y-1.5">
                  {aiReport.report.cross_survey_patterns.map((p, i) => (
                    <li key={i} className="text-[13px] text-ink-soft leading-relaxed flex gap-3">
                      <span className="shrink-0 mt-2 w-1.5 h-1.5 rounded-full bg-brand-500" />
                      <span>{p}</span>
                    </li>
                  ))}
                </ul>
              </SubSection>
            )}

            <SubSection title="التوقّع — 30 يوماً">
              <p className="text-[13px] text-ink-soft leading-loose font-light">
                {aiReport.report.predicted_trend}
              </p>
            </SubSection>

            <p className="text-[10px] text-ink-mute font-mono pt-3 border-t border-ink-line/40">
              {aiReport.model} • {aiReport.prompt_version} • {new Date(aiReport.generated_at).toLocaleString("en-US")}
            </p>
          </div>
        </section>
      )}

      {timeline && timeline.series.length > 0 && (
        <section className="mb-8 print:break-inside-avoid">
          <div className="text-[10px] font-bold uppercase tracking-[0.22em] text-brand-600 mb-2">DAILY DATA</div>
          <h2 className="text-xl font-display font-black text-ink mb-3 tracking-tight">العيّنة اليوميّة</h2>
          <table className="w-full text-[12px]">
            <thead>
              <tr className="text-[10px] uppercase tracking-[0.14em] text-ink-mute border-b border-ink-line/60">
                <th className="px-3 py-2 text-start font-bold">التاريخ</th>
                <th className="px-3 py-2 text-end font-bold">المزاج</th>
                <th className="px-3 py-2 text-end font-bold">العيّنة</th>
                <th className="px-3 py-2 text-end font-bold">استطلاعات</th>
                <th className="px-3 py-2 text-end font-bold">استبيانات</th>
              </tr>
            </thead>
            <tbody>
              {timeline.series.filter((s) => s.sample > 0).map((s) => (
                <tr key={s.date} className="border-b border-ink-line/30">
                  <td className="px-3 py-2 font-mono text-ink-soft">{s.date}</td>
                  <td className="px-3 py-2 text-end tabular text-ink font-bold">{s.sentiment.toFixed(0)}</td>
                  <td className="px-3 py-2 text-end tabular text-ink-soft">{fmtInt(s.sample)}</td>
                  <td className="px-3 py-2 text-end tabular text-ink-soft">{fmtInt(s.polls)}</td>
                  <td className="px-3 py-2 text-end tabular text-ink-soft">{fmtInt(s.surveys)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}

      <footer className="mt-12 pt-6 border-t border-ink-line text-center text-[10px] text-ink-mute font-mono">
        © TRENDX {new Date().getFullYear()} — تقرير سرّي للناشر فقط
      </footer>
    </main>
  );
}

function Cell({ label, value }: { label: string; value: string }) {
  return (
    <div className="border border-ink-line/60 rounded-chip p-4 text-center">
      <div className="text-3xl font-display font-black tabular text-brand-600 leading-none tracking-tight">{value}</div>
      <div className="text-[10px] uppercase tracking-[0.14em] text-ink-mute mt-2">{label}</div>
    </div>
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
