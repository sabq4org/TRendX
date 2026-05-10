"use client";

import { use, useState } from "react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { ChartCard } from "@/components/ChartCard";
import { KPICard } from "@/components/KPICard";
import { Gauge } from "@/components/charts/Gauge";
import { BubbleScatter } from "@/components/charts/Bubble";
import { fmtInt } from "@/lib/format";
import clsx from "clsx";
import type { SectorAIReport } from "@/lib/types";
import { Sparkles, Download } from "lucide-react";
import { SentimentTimelineCard } from "@/components/sector/SentimentTimelineCard";

export default function SectorDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { token } = useAuth();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);
  const [report, setReport] = useState<{ loading: boolean; data: SectorAIReport | null; error: string | null }>(
    { loading: false, data: null, error: null },
  );

  const topic = bootstrap.data?.topics.find((t) => t.id === id);
  const polls = bootstrap.data?.polls.filter((p) => p.topic_id === id) ?? [];
  const surveys = bootstrap.data?.surveys.filter((s) => s.topic_id === id) ?? [];
  const totalVotes = polls.reduce((acc, p) => acc + p.total_votes, 0);
  const totalResponses = surveys.reduce((acc, s) => acc + s.total_responses, 0);

  async function loadReport() {
    if (!token || report.loading) return;
    setReport({ loading: true, data: null, error: null });
    try {
      const data = await api.topicInsight(token, id);
      setReport({ loading: false, data, error: null });
    } catch (err) {
      setReport({ loading: false, data: null, error: err instanceof Error ? err.message : String(err) });
    }
  }

  if (bootstrap.loading) {
    return (
      <>
        <Header eyebrow="SECTOR INTELLIGENCE" title="بانتظار…" />
        <main className="px-10 pb-10 grid gap-6 grid-cols-3">
          {[0, 1, 2].map((i) => <div key={i} className="h-72 rounded-card shimmer" />)}
        </main>
      </>
    );
  }

  const bubbles = polls.map((p) => {
    const leading = [...p.options].sort((a, b) => b.votes_count - a.votes_count)[0];
    const leadingPct = p.total_votes > 0 && leading ? (leading.votes_count / p.total_votes) * 100 : 0;
    return {
      name: p.title, x: p.total_votes, y: Math.round(leadingPct), size: p.total_votes,
    };
  });

  return (
    <>
      <Header
        eyebrow="SECTOR INTELLIGENCE"
        title={topic ? topic.name : "قطاع"}
        subtitle="ذكاء عابر للقطاع — اتّجاه، إجماع، شخصية، تنبّؤ."
        right={
          <button
            onClick={() => token && window.open(`/reports/sector/${id}?token=${token}`, "_blank")}
            className="inline-flex items-center gap-1.5 text-[11px] font-bold px-3 py-2 rounded-chip border border-ink-line hover:border-brand-500 hover:text-brand-600 transition"
          >
            <Download size={12} /> تقرير قابل للطباعة
          </button>
        }
      />

      <main className="flex-1 px-10 pb-10 space-y-7">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-6 stagger">
          <KPICard index={0} tone="brand" label="استطلاعات" value={fmtInt(polls.length)} />
          <KPICard index={1} tone="accent" label="استبيانات" value={fmtInt(surveys.length)} />
          <KPICard index={2} tone="ai" label="إجمالي الأصوات" value={fmtInt(totalVotes)} />
          <KPICard index={3} tone="brand" label="إجمالي الاستجابات" value={fmtInt(totalResponses)} />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 stagger">
          <ChartCard
            eyebrow="SENTIMENT"
            title="مزاج القطاع"
            subtitle="مؤشر تجميعي 0-100 من تقرير AI"
            height={260}
          >
            {report.data ? (
              <Gauge
                value={report.data.report.sector_sentiment_score}
                label={
                  report.data.report.sentiment_direction === "rising" ? "صعودي" :
                  report.data.report.sentiment_direction === "falling" ? "هبوطي" : "مستقرّ"
                }
                sub={report.data.prompt_version}
              />
            ) : (
              <div className="h-full grid place-items-center text-[12px] text-ink-mute dotgrid rounded-chip">
                ولّد تقرير AI لرؤية مؤشّر المزاج.
              </div>
            )}
          </ChartCard>

          <ChartCard
            className="lg:col-span-2"
            eyebrow="DISTRIBUTION"
            title="استطلاعات القطاع — حصص الإجماع"
            subtitle="X: حجم الأصوات • Y: نسبة الخيار الرائد • حجم الفقاعة: العيّنة"
            height={300}
          >
            {bubbles.length > 0 ? (
              <BubbleScatter data={bubbles} xLabel="إجمالي الأصوات" yLabel="نسبة الخيار الرائد %" />
            ) : (
              <div className="h-full grid place-items-center text-[12px] text-ink-mute">
                لا توجد استطلاعات في هذا القطاع.
              </div>
            )}
          </ChartCard>
        </div>

        <div className="grid grid-cols-1 gap-6 stagger">
          <SentimentTimelineCard topicId={id} />
        </div>

        <div className="bg-canvas-card rounded-card shadow-card p-8">
          <div className="flex items-center justify-between mb-6">
            <div>
              <div className="text-eyebrow text-brand-600 mb-1.5">SECTOR REPORT</div>
              <h3 className="text-xl font-display font-black text-ink tracking-tight">
                تقرير الذكاء القطاعي
              </h3>
            </div>
            <button
              onClick={loadReport}
              disabled={report.loading}
              className="bg-brand-600 hover:bg-brand-700 disabled:bg-brand-300 text-canvas-card font-bold py-2.5 px-5 rounded-chip text-xs transition shadow-card hover:shadow-card-lift inline-flex items-center gap-2"
            >
              <Sparkles size={12} /> {report.loading ? "جارٍ التوليد…" : report.data ? "إعادة التوليد" : "توليد التقرير"}
            </button>
          </div>

          {report.error && <div className="text-xs text-negative mb-4">{report.error}</div>}

          {report.data ? (
            <SectorReportBody report={report.data} />
          ) : !report.loading ? (
            <p className="text-[13px] text-ink-mute leading-relaxed font-light">
              يحلّل التقرير القطاعي جميع الاستطلاعات والاستبيانات في هذا القطاع ويُصدر:
              مؤشّر مزاج (0-100)، خريطة إجماع، شخصية القطاع الغالبة، أنماط مشتركة بين الاستبيانات،
              بريف استراتيجي مكوّن من 4-5 فقرات، وتوقّع لاتّجاه القطاع خلال 30 يوماً.
            </p>
          ) : null}
        </div>

        <div className="bg-canvas-card rounded-card shadow-card overflow-hidden">
          <div className="px-8 py-6 border-b border-ink-line/40">
            <div className="text-eyebrow text-brand-600 mb-1">POLLS IN SECTOR</div>
            <h3 className="text-xl font-display font-black text-ink tracking-tight">استطلاعات القطاع</h3>
          </div>
          <ul>
            {polls.map((p, idx) => (
              <li key={p.id} className="border-b border-ink-line/30 last:border-0">
                <a
                  href={`/polls/${p.id}`}
                  className="flex items-center gap-5 px-8 py-4 hover:bg-canvas-well/50 transition group"
                >
                  <span className="text-[11px] font-mono font-bold tabular text-ink-mute w-7">
                    {String(idx + 1).padStart(2, "0")}
                  </span>
                  <span className="text-[14px] text-ink truncate flex-1 group-hover:text-brand-600 transition">{p.title}</span>
                  <span className="shrink-0 text-end">
                    <span className="text-xl font-display font-black tabular text-ink">{fmtInt(p.total_votes)}</span>
                    <span className="text-[10px] uppercase tracking-[0.14em] text-ink-mute ms-2">صوت</span>
                  </span>
                </a>
              </li>
            ))}
          </ul>
        </div>
      </main>
    </>
  );
}

function SectorReportBody({ report }: { report: SectorAIReport }) {
  const r = report.report;
  return (
    <div className="space-y-5">
      <div className="bg-canvas-well rounded-chip p-6">
        <div className="text-eyebrow text-brand-600 mb-2">STRATEGIC BRIEF</div>
        <p className="text-[15px] text-ink-soft leading-loose whitespace-pre-line font-light">
          {r.strategic_brief}
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-canvas-well rounded-chip p-5">
          <div className="text-eyebrow text-brand-600 mb-2">SECTOR PERSONA</div>
          <div className="font-display font-black text-xl text-ink tracking-tight mb-1">
            {r.sector_persona.name}
            <span className="font-display font-black tabular text-brand-600 text-base ms-2">
              {r.sector_persona.share_pct}%
            </span>
          </div>
          <p className="text-[13px] text-ink-soft leading-relaxed font-light">{r.sector_persona.description}</p>
        </div>
        <div className="bg-canvas-well rounded-chip p-5">
          <div className="text-eyebrow text-brand-600 mb-2">30-DAY FORECAST</div>
          <p className="text-[14px] text-ink-soft leading-relaxed font-light">{r.predicted_trend}</p>
        </div>
      </div>

      {r.consensus_map.length > 0 && (
        <div>
          <div className="text-eyebrow text-brand-600 mb-3">CONSENSUS MAP</div>
          <ul className="space-y-2">
            {r.consensus_map.map((c, i) => (
              <li key={i} className="flex items-center gap-3 text-[14px] p-3 rounded-chip hover:bg-canvas-well/50 transition">
                <span className={clsx(
                  "shrink-0 px-2.5 py-0.5 rounded-pill text-[10px] font-bold",
                  c.label === "إجماع قوي" && "bg-positive-soft text-positive",
                  c.label === "ميل واضح" && "bg-brand-50 text-brand-600",
                  c.label === "اختلاف خفيف" && "bg-accent-50 text-accent-700",
                  c.label === "انقسام حاد" && "bg-negative-soft text-negative",
                )}>
                  {c.label}
                </span>
                <span className="text-ink-soft flex-1">{c.question}</span>
                <span className="font-display font-black tabular text-ink">{c.leading_pct}%</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {r.cross_survey_patterns.length > 0 && (
        <div>
          <div className="text-eyebrow text-brand-600 mb-3">CROSS-SURVEY PATTERNS</div>
          <ul className="space-y-2">
            {r.cross_survey_patterns.map((p, i) => (
              <li key={i} className="text-[14px] text-ink-soft flex items-start gap-3 leading-relaxed">
                <span className="shrink-0 mt-2 w-1.5 h-1.5 rounded-full bg-brand-500" />
                <span>{p}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
