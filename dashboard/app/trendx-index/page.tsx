"use client";

export const dynamic = "force-dynamic";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { TrendXIndex } from "@/lib/types";
import { fmtInt } from "@/lib/format";
import { TrendingUp, TrendingDown, Minus, ArrowLeft, Activity } from "lucide-react";
import Link from "next/link";

/**
 * Public TRENDX Index — accessible without auth, designed to be linked
 * from journalism articles, social, etc. Reflects the live national
 * mood across six dimensions.
 */
export default function PublicIndexPage() {
  const [data, setData] = useState<TrendXIndex | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api
      .trendxIndex()
      .then(setData)
      .catch((e) => setError(e instanceof Error ? e.message : String(e)));
  }, []);

  if (error) {
    return (
      <main className="min-h-screen px-6 md:px-12 py-12 max-w-5xl mx-auto">
        <div className="bg-canvas-card rounded-card p-8 text-negative">{error}</div>
      </main>
    );
  }
  if (!data) {
    return (
      <main className="min-h-screen px-6 md:px-12 py-12 max-w-5xl mx-auto space-y-6">
        <div className="h-32 rounded-card shimmer" />
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {[0, 1, 2, 3, 4, 5].map((i) => (
            <div key={i} className="h-44 rounded-card shimmer" />
          ))}
        </div>
      </main>
    );
  }

  const compositeDir =
    data.composite_change_24h > 0 ? "up" :
    data.composite_change_24h < 0 ? "down" : "flat";

  return (
    <main className="min-h-screen px-6 md:px-12 py-12 max-w-6xl mx-auto">
      {/* Header */}
      <header className="mb-10">
        <div className="flex items-center justify-between mb-6">
          <Link href="/" className="text-sm font-bold text-brand-600 inline-flex items-center gap-1.5 hover:underline">
            <ArrowLeft size={14} /> TRENDX
          </Link>
          <span className="text-[11px] font-bold text-ink-mute tabular">
            تحديث: {new Date(data.computed_at).toLocaleString("ar-SA", { dateStyle: "medium", timeStyle: "short" })}
          </span>
        </div>
        <div className="flex items-center gap-2 mb-3">
          <Activity size={16} className="text-brand-500" />
          <span className="text-eyebrow text-brand-600">مؤشّر TRENDX اليومي</span>
        </div>
        <h1 className="text-5xl md:text-7xl font-display font-black text-ink tracking-tight leading-none mb-2">
          نبض السعودية
        </h1>
        <p className="text-base md:text-lg text-ink-soft mt-3 max-w-2xl">
          لقطة يوميّة لاتجاهات الرأي العامّ في ستّ محاور رئيسية، مستخلَصة من
          استطلاعات وأصوات المستجيبين على منصّة TRENDX.
        </p>
      </header>

      {/* Composite hero card */}
      <section className="bg-canvas-card rounded-card p-8 md:p-12 shadow-card-lift relative overflow-hidden mb-12">
        <div className="absolute inset-0 bg-hero opacity-60 pointer-events-none" />
        <div className="relative grid grid-cols-1 md:grid-cols-3 gap-8 items-center">
          <div className="md:col-span-2">
            <div className="text-eyebrow text-brand-600 mb-2">المؤشّر المركّب</div>
            <div className="flex items-baseline gap-4">
              <span className="text-kpi-hero ai-text-gradient tabular">{data.composite}</span>
              <span className="text-2xl text-ink-mute font-medium">/ 100</span>
            </div>
            <div className="mt-3 flex items-center gap-2 text-sm">
              <DirectionIcon direction={compositeDir} />
              <span className={
                compositeDir === "up" ? "text-positive font-bold" :
                compositeDir === "down" ? "text-negative font-bold" :
                "text-ink-mute"
              }>
                {data.composite_change_24h > 0 ? "+" : ""}{data.composite_change_24h} نقطة عن الأمس
              </span>
            </div>
          </div>
          <div className="md:text-end">
            <div className="text-eyebrow text-ink-mute mb-2">أساس العيّنة</div>
            <div className="text-3xl font-display font-bold text-ink tabular">{fmtInt(data.total_responses)}</div>
            <div className="text-[12px] text-ink-mute">إجابة في آخر 7 أيام</div>
          </div>
        </div>
      </section>

      {/* Indicators grid */}
      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 stagger">
        {data.metrics.map((m) => (
          <article
            key={m.slug}
            className="bg-canvas-card rounded-card p-6 shadow-card hover:shadow-card-lift transition-all"
          >
            <div className="flex items-center justify-between mb-3">
              <span className="text-eyebrow text-brand-600">{m.name}</span>
              <DirectionIcon direction={m.direction} />
            </div>
            <div className="flex items-baseline gap-2 mb-1">
              <span className="text-kpi tabular text-ink">{m.value}</span>
              <span className="text-base text-ink-mute font-medium">/ 100</span>
            </div>
            <div className="text-[12px] flex items-center gap-2 mb-3">
              <span className={
                m.direction === "up" ? "text-positive font-bold" :
                m.direction === "down" ? "text-negative font-bold" :
                "text-ink-mute"
              }>
                {m.change_24h > 0 ? "+" : ""}{m.change_24h} 24س
              </span>
              <span className="text-ink-ghost">·</span>
              <span className="text-ink-mute tabular">{fmtInt(m.sample_size)} إجابة</span>
            </div>
            <p className="text-sm text-ink-soft leading-relaxed">{m.blurb}</p>
            {/* Sparkbar */}
            <div className="mt-4 h-1.5 bg-canvas-well rounded-pill overflow-hidden">
              <div
                className="h-full bg-brand-gradient rounded-pill transition-all duration-700"
                style={{ width: `${m.value}%` }}
              />
            </div>
          </article>
        ))}
      </section>

      <footer className="mt-16 text-center text-[12px] text-ink-mute">
        <p>
          البيانات مفتوحة للاستشهاد بشرط ذكر TRENDX كمصدر · 
          <Link href="/" className="text-brand-600 font-bold hover:underline ms-1">
            أنشئ استبيانك الخاصّ
          </Link>
        </p>
      </footer>
    </main>
  );
}

function DirectionIcon({ direction }: { direction: "up" | "down" | "flat" }) {
  if (direction === "up") return <TrendingUp size={18} className="text-positive" />;
  if (direction === "down") return <TrendingDown size={18} className="text-negative" />;
  return <Minus size={18} className="text-ink-mute" />;
}
