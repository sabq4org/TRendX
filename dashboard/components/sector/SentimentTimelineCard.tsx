"use client";

import { useEffect, useState } from "react";
import { TrendingUp, TrendingDown, Minus } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { ChartCard } from "@/components/ChartCard";
import { AreaTrend } from "@/components/charts/Area";
import type { SentimentTimeline } from "@/lib/types";

const PRESETS = [
  { value: 7,  label: "٧ أيام" },
  { value: 30, label: "٣٠ يوم" },
  { value: 90, label: "٩٠ يوم" },
];

export function SentimentTimelineCard({ topicId }: { topicId: string }) {
  const { token } = useAuth();
  const [days, setDays] = useState(30);
  const [data, setData] = useState<SentimentTimeline | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!token) return;
    let cancelled = false;
    setLoading(true);
    api.topicSentimentTimeline(token, topicId, days)
      .then((d) => { if (!cancelled) setData(d); })
      .catch(() => {})
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [token, topicId, days]);

  return (
    <ChartCard
      className="lg:col-span-3"
      eyebrow="SENTIMENT TIMELINE"
      title="مسار المزاج عبر الزمن"
      subtitle={data ? `الحالي ${data.current_score} • Δ ${data.delta_30d > 0 ? "+" : ""}${data.delta_30d}` : "بانتظار البيانات"}
      height={260}
      action={
        <div className="flex gap-1 bg-canvas-well rounded-pill p-1">
          {PRESETS.map((p) => (
            <button
              key={p.value}
              onClick={() => setDays(p.value)}
              className={
                "px-3 py-1.5 rounded-pill text-[11px] font-bold transition " +
                (days === p.value
                  ? "bg-canvas-card text-brand-600 shadow-card"
                  : "text-ink-mute hover:text-ink")
              }
            >
              {p.label}
            </button>
          ))}
          {data && <DirectionPill direction={data.direction} />}
        </div>
      }
    >
      {loading && (
        <div className="h-full grid place-items-center">
          <div className="w-8 h-8 rounded-full border-2 border-ink-line border-t-brand-500 animate-spin" />
        </div>
      )}
      {!loading && data && (
        <AreaTrend
          data={data.series.map((s) => ({ day: s.date.slice(5), value: s.sentiment }))}
          accent="#3B5BDB"
        />
      )}
      {!loading && !data && (
        <div className="h-full grid place-items-center text-[12px] text-ink-mute dotgrid rounded-chip">
          لا توجد بيانات كافية لرسم الاتجاه.
        </div>
      )}
    </ChartCard>
  );
}

function DirectionPill({ direction }: { direction: "rising" | "falling" | "stable" }) {
  const map = {
    rising:  { Icon: TrendingUp,   bg: "bg-positive-soft", txt: "text-positive" },
    falling: { Icon: TrendingDown, bg: "bg-negative-soft", txt: "text-negative" },
    stable:  { Icon: Minus,        bg: "bg-canvas-well",   txt: "text-ink-mute" },
  };
  const { Icon, bg, txt } = map[direction];
  return (
    <span className={`ms-2 inline-flex items-center gap-1 px-2.5 py-1 rounded-pill ${bg} ${txt} text-[10px] font-bold`}>
      <Icon size={11} />
    </span>
  );
}
