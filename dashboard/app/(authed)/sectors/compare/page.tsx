"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowLeft, TrendingUp, TrendingDown, Minus, Crown } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt, fmtPctRaw } from "@/lib/format";
import clsx from "clsx";
import type { SectorBenchmark } from "@/lib/types";

export default function SectorComparePage() {
  const { token } = useAuth();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);
  const [selected, setSelected] = useState<string[]>([]);
  const [data, setData] = useState<SectorBenchmark | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Pre-select first 3 topics on initial load
    if (bootstrap.data && selected.length === 0 && bootstrap.data.topics.length > 0) {
      setSelected(bootstrap.data.topics.slice(0, 3).map((t) => t.id));
    }
  }, [bootstrap.data, selected.length]);

  useEffect(() => {
    if (!token || selected.length < 2) { setData(null); return; }
    let cancelled = false;
    setLoading(true);
    setError(null);
    api
      .sectorBenchmark(token, selected)
      .then((d) => { if (!cancelled) setData(d); })
      .catch((err) => { if (!cancelled) setError(err instanceof Error ? err.message : String(err)); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [token, selected]);

  function toggle(id: string) {
    setSelected((prev) => prev.includes(id)
      ? prev.filter((x) => x !== id)
      : prev.length >= 6 ? prev : [...prev, id]);
  }

  return (
    <>
      <Header
        eyebrow="SECTOR BENCHMARK"
        title="مقارنة القطاعات"
        subtitle="اختر حتى ٦ قطاعات وقارنها على المؤشرات الاستراتيجية. التحديث كل ٣٠ دقيقة."
        right={
          <Link
            href="/sectors"
            className="inline-flex items-center gap-1.5 text-[11px] font-bold text-ink-mute hover:text-brand-600 transition"
          >
            <ArrowLeft size={12} className="rotate-180" /> كل القطاعات
          </Link>
        }
      />

      <main className="flex-1 px-10 pb-10 space-y-7">
        {/* Sector picker */}
        <div className="bg-canvas-card rounded-card shadow-card p-6">
          <div className="text-eyebrow text-brand-600 mb-3">PICK SECTORS</div>
          <h3 className="text-base font-display font-bold text-ink mb-5 tracking-tight">
            القطاعات المختارة ({selected.length} / 6)
          </h3>
          <div className="flex flex-wrap gap-2">
            {bootstrap.data?.topics.map((t) => {
              const isSelected = selected.includes(t.id);
              return (
                <button
                  key={t.id}
                  onClick={() => toggle(t.id)}
                  disabled={!isSelected && selected.length >= 6}
                  className={clsx(
                    "px-4 py-2 rounded-pill text-sm font-bold transition",
                    isSelected
                      ? "brand-fill shadow-card"
                      : "bg-canvas-well text-ink-soft hover:text-ink disabled:opacity-40 disabled:cursor-not-allowed",
                  )}
                >
                  {t.name}
                </button>
              );
            })}
          </div>
        </div>

        {/* Result */}
        {selected.length < 2 && (
          <div className="bg-canvas-card rounded-card p-12 text-center text-ink-mute dotgrid">
            <p className="text-sm">اختر قطاعين على الأقل لبدء المقارنة.</p>
          </div>
        )}

        {selected.length >= 2 && loading && (
          <div className="bg-canvas-card rounded-card p-16 text-center">
            <div className="w-10 h-10 mx-auto rounded-full border-2 border-ink-line border-t-brand-500 animate-spin mb-4" />
            <p className="text-sm text-ink-mute">جارٍ حساب البنشمارك…</p>
          </div>
        )}

        {error && (
          <div className="bg-negative-soft border border-negative/20 rounded-card p-6 text-sm text-negative">
            {error}
          </div>
        )}

        {data && data.rows.length > 0 && (
          <>
            {/* Leaderboard cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 stagger">
              <Leader title="الأكثر تفاعلاً" topicId={data.leaders.by_engagement} rows={data.rows} />
              <Leader title="الأعلى إكمالاً" topicId={data.leaders.by_completion} rows={data.rows} />
              <Leader title="الأفضل مزاجاً" topicId={data.leaders.by_sentiment} rows={data.rows} />
              <Leader title="الأكثر متابعةً" topicId={data.leaders.by_followers} rows={data.rows} />
            </div>

            {/* Comparison table */}
            <div className="bg-canvas-card rounded-card shadow-card overflow-hidden">
              <div className="px-7 py-5 border-b border-ink-line/40">
                <div className="text-eyebrow text-brand-600 mb-1">FULL COMPARISON</div>
                <h3 className="text-base font-display font-bold text-ink tracking-tight">
                  جدول المؤشّرات
                </h3>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="text-[10px] uppercase tracking-[0.14em] text-ink-mute border-b border-ink-line/40">
                      <Th>القطاع</Th>
                      <Th align="end">استطلاعات</Th>
                      <Th align="end">استبيانات</Th>
                      <Th align="end">أصوات</Th>
                      <Th align="end">استجابات</Th>
                      <Th align="end">إكمال %</Th>
                      <Th align="end">متابعون</Th>
                      <Th align="end">المزاج</Th>
                      <Th align="end">الاتجاه</Th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.rows.map((r) => (
                      <tr key={r.topic_id} className="border-b border-ink-line/30 hover:bg-canvas-well/50 transition">
                        <td className="px-7 py-4">
                          <div className="font-display font-bold text-ink">{r.topic_name}</div>
                          <div className="text-[10px] font-mono text-ink-mute">{r.topic_slug}</div>
                        </td>
                        <Td align="end">{fmtInt(r.polls_count)}</Td>
                        <Td align="end">{fmtInt(r.surveys_count)}</Td>
                        <Td align="end">{fmtInt(r.total_votes)}</Td>
                        <Td align="end">{fmtInt(r.total_responses)}</Td>
                        <Td align="end">{fmtPctRaw(r.avg_completion_rate, 0)}</Td>
                        <Td align="end">{fmtInt(r.followers_count)}</Td>
                        <Td align="end">
                          {r.sentiment_score !== null ? (
                            <span className="font-display font-black text-brand-600 tabular">
                              {r.sentiment_score.toFixed(0)}
                            </span>
                          ) : (
                            <span className="text-ink-ghost">—</span>
                          )}
                        </Td>
                        <td className="px-5 py-4 text-end">
                          <DirectionPill direction={r.sentiment_direction} />
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </>
        )}
      </main>
    </>
  );
}

function Leader({
  title, topicId, rows,
}: { title: string; topicId: string | null; rows: SectorBenchmark["rows"] }) {
  const row = rows.find((r) => r.topic_id === topicId);
  return (
    <div className="bg-canvas-card rounded-card shadow-card p-5 relative overflow-hidden">
      <span className="accent-bar text-brand-500" aria-hidden />
      <div className="text-eyebrow text-ink-mute mb-2 flex items-center gap-1.5">
        <Crown size={11} className="text-accent-500" /> {title}
      </div>
      <div className="text-xl font-display font-black text-ink tracking-tight leading-tight">
        {row?.topic_name ?? "—"}
      </div>
    </div>
  );
}

function Th({ children, align }: { children: React.ReactNode; align?: "end" }) {
  return (
    <th className={`px-5 py-4 ${align === "end" ? "text-end" : "text-start"} font-bold`}>
      {children}
    </th>
  );
}

function Td({ children, align }: { children: React.ReactNode; align?: "end" }) {
  return (
    <td className={`px-5 py-4 tabular ${align === "end" ? "text-end" : "text-start"} text-ink-soft`}>
      {children}
    </td>
  );
}

function DirectionPill({ direction }: { direction: "rising" | "falling" | "stable" | null }) {
  if (!direction) return <span className="text-ink-ghost text-xs">—</span>;
  const map = {
    rising:  { Icon: TrendingUp,   label: "صاعد",  bg: "bg-positive-soft", txt: "text-positive" },
    falling: { Icon: TrendingDown, label: "هابط",  bg: "bg-negative-soft", txt: "text-negative" },
    stable:  { Icon: Minus,        label: "مستقر", bg: "bg-canvas-well",   txt: "text-ink-mute" },
  };
  const { Icon, label, bg, txt } = map[direction];
  return (
    <span className={`inline-flex items-center gap-1.5 text-[10px] font-bold px-2.5 py-1 rounded-pill ${bg} ${txt}`}>
      <Icon size={11} /> {label}
    </span>
  );
}
