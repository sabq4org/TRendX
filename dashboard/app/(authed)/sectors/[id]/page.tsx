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
      setReport({
        loading: false,
        data: null,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }

  if (bootstrap.loading) {
    return (
      <>
        <Header title="بانتظار…" />
        <main className="px-9 py-6 grid gap-5 grid-cols-3">
          {[0, 1, 2].map((i) => <div key={i} className="h-72 rounded-card shimmer" />)}
        </main>
      </>
    );
  }

  // Bubble chart: each poll as a bubble (x=total_votes, y=leading%, size=total_votes)
  const bubbles = polls.map((p) => {
    const leading = [...p.options].sort((a, b) => b.votes_count - a.votes_count)[0];
    const leadingPct = p.total_votes > 0 && leading ? (leading.votes_count / p.total_votes) * 100 : 0;
    return {
      name: p.title,
      x: p.total_votes,
      y: Math.round(leadingPct),
      size: p.total_votes,
    };
  });

  return (
    <>
      <Header
        title={topic ? `قطاع — ${topic.name}` : "قطاع"}
        subtitle="الذكاء القطاعي العابر — اتّجاه، إجماع، شخصية، تنبّؤ."
      />

      <main className="flex-1 px-9 py-6 space-y-6">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
          <KPICard label="استطلاعات" value={fmtInt(polls.length)} accent="brand" />
          <KPICard label="استبيانات" value={fmtInt(surveys.length)} />
          <KPICard label="إجمالي الأصوات" value={fmtInt(totalVotes)} />
          <KPICard label="إجمالي الاستجابات" value={fmtInt(totalResponses)} />
        </div>

        {/* Gauge + Bubble */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
          <ChartCard
            title="مزاج القطاع"
            subtitle="مؤشر تجميعي 0-100 من تقرير AI"
            height={240}
          >
            {report.data ? (
              <Gauge
                value={report.data.report.sector_sentiment_score}
                label={
                  report.data.report.sentiment_direction === "rising"
                    ? "صعودي"
                    : report.data.report.sentiment_direction === "falling"
                      ? "هبوطي"
                      : "مستقرّ"
                }
                sub={`نسخة Prompt: ${report.data.prompt_version}`}
              />
            ) : (
              <div className="h-full grid place-items-center text-xs text-ink-mute">
                ولّد تقرير AI لرؤية مؤشّر المزاج.
              </div>
            )}
          </ChartCard>

          <ChartCard
            title="استطلاعات القطاع — حصص الإجماع"
            subtitle="X: حجم الأصوات · Y: نسبة الخيار الرائد · حجم الفقاعة: العيّنة"
            className="lg:col-span-2"
            height={300}
          >
            {bubbles.length > 0 ? (
              <BubbleScatter data={bubbles} xLabel="إجمالي الأصوات" yLabel="نسبة الخيار الرائد %" />
            ) : (
              <div className="h-full grid place-items-center text-xs text-ink-mute">
                لا توجد استطلاعات في هذا القطاع.
              </div>
            )}
          </ChartCard>
        </div>

        {/* AI Report */}
        <div className="bg-canvas-card rounded-card shadow-card p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-bold text-ink">تقرير الذكاء القطاعي</h3>
            <button
              onClick={loadReport}
              disabled={report.loading}
              className="bg-brand-500 hover:bg-brand-600 disabled:bg-brand-300 text-white font-bold py-2 px-4 rounded-chip text-xs transition"
            >
              {report.loading ? "جارٍ التوليد…" : report.data ? "إعادة التوليد" : "✨ توليد التقرير"}
            </button>
          </div>

          {report.error && (
            <div className="text-xs text-danger mb-4">{report.error}</div>
          )}

          {report.data ? (
            <SectorReportBody report={report.data} />
          ) : !report.loading ? (
            <p className="text-xs text-ink-mute leading-relaxed">
              يحلّل التقرير القطاعي جميع الاستطلاعات والاستبيانات في هذا القطاع ويُصدر:
              مؤشّر مزاج (0-100)، خريطة إجماع، شخصية القطاع الغالبة، أنماط مشتركة بين الاستبيانات،
              بريف استراتيجي مكوّن من 4-5 فقرات، وتوقّع لاتّجاه القطاع خلال 30 يوماً.
            </p>
          ) : null}
        </div>

        {/* Polls in sector */}
        <div className="bg-canvas-card rounded-card shadow-card p-6">
          <h3 className="text-sm font-bold text-ink mb-4">استطلاعات القطاع</h3>
          <ul className="divide-y divide-ink-line">
            {polls.map((p) => (
              <li key={p.id}>
                <a
                  href={`/polls/${p.id}`}
                  className="flex items-center justify-between py-3 hover:bg-canvas-well/50 -mx-2 px-2 rounded-chip transition"
                >
                  <span className="text-sm text-ink truncate flex-1 ms-3">{p.title}</span>
                  <span className="text-sm font-bold tabular text-ink shrink-0">
                    {fmtInt(p.total_votes)}
                    <span className="text-[10px] text-ink-mute font-medium me-1"> صوت</span>
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
      <div className="bg-canvas-well rounded-chip p-4">
        <div className="text-[10px] font-bold uppercase tracking-wide text-ink-mute mb-1.5">
          البريف الاستراتيجي
        </div>
        <p className="text-sm text-ink-soft leading-relaxed whitespace-pre-line">{r.strategic_brief}</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-canvas-well rounded-chip p-4">
          <div className="text-[10px] font-bold uppercase tracking-wide text-ink-mute mb-2">
            شخصية القطاع
          </div>
          <div className="text-base font-bold text-ink mb-1">
            {r.sector_persona.name} <span className="text-sm tabular text-brand-600">({r.sector_persona.share_pct}%)</span>
          </div>
          <p className="text-xs text-ink-soft leading-relaxed">{r.sector_persona.description}</p>
        </div>
        <div className="bg-canvas-well rounded-chip p-4">
          <div className="text-[10px] font-bold uppercase tracking-wide text-ink-mute mb-2">
            توقّع 30 يوم
          </div>
          <p className="text-sm text-ink-soft leading-relaxed">{r.predicted_trend}</p>
        </div>
      </div>

      {r.consensus_map.length > 0 && (
        <div>
          <div className="text-[10px] font-bold uppercase tracking-wide text-ink-mute mb-2">
            خريطة الإجماع
          </div>
          <ul className="space-y-2">
            {r.consensus_map.map((c, i) => (
              <li key={i} className="flex items-center gap-3 text-sm">
                <span className={clsx(
                  "shrink-0 px-2 py-0.5 rounded-full text-[10px] font-bold",
                  c.label === "إجماع قوي" && "bg-success/10 text-success",
                  c.label === "ميل واضح" && "bg-brand-50 text-brand-700",
                  c.label === "اختلاف خفيف" && "bg-amber-50 text-amber-700",
                  c.label === "انقسام حاد" && "bg-danger/10 text-danger",
                )}>
                  {c.label}
                </span>
                <span className="text-ink-soft flex-1">{c.question}</span>
                <span className="font-bold tabular text-ink">{c.leading_pct}%</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {r.cross_survey_patterns.length > 0 && (
        <div>
          <div className="text-[10px] font-bold uppercase tracking-wide text-ink-mute mb-2">
            أنماط عابرة للاستبيانات
          </div>
          <ul className="space-y-1.5">
            {r.cross_survey_patterns.map((p, i) => (
              <li key={i} className="text-sm text-ink-soft flex items-start gap-2 leading-relaxed">
                <span className="shrink-0 mt-1.5 w-1.5 h-1.5 rounded-full bg-brand-500" />
                <span>{p}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
