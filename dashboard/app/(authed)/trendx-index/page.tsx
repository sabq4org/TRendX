"use client";

export const dynamic = "force-dynamic";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { TrendXIndex } from "@/lib/types";
import { fmtInt } from "@/lib/format";
import { Header } from "@/components/Header";
import { TrendingUp, TrendingDown, Minus, ExternalLink, Copy } from "lucide-react";
import Link from "next/link";

/**
 * Dashboard view of the TRENDX Index. Mirrors the public /embed/index
 * page but lives inside the authed shell (Sidebar + Header) and adds
 * a small "publish" toolbar (open public page, copy embed snippet).
 */
export default function IndexPage() {
  const [data, setData] = useState<TrendXIndex | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    api
      .trendxIndex()
      .then(setData)
      .catch((e) => setError(e instanceof Error ? e.message : String(e)));
  }, []);

  const subtitle = data
    ? `لقطة يوميّة لاتجاهات الرأي العامّ في ستّ محاور رئيسية · تحديث ${new Date(
        data.computed_at,
      ).toLocaleString("ar-SA", { dateStyle: "medium", timeStyle: "short" })}`
    : "لقطة يوميّة لاتجاهات الرأي العامّ في ستّ محاور رئيسية.";

  if (error) {
    return (
      <>
        <Header eyebrow="مؤشّر TRENDX اليومي" title="نبض السعودية" subtitle={subtitle} />
        <main className="px-10 pb-10">
          <div className="bg-canvas-card rounded-card p-8 text-negative">{error}</div>
        </main>
      </>
    );
  }
  if (!data) {
    return (
      <>
        <Header eyebrow="مؤشّر TRENDX اليومي" title="نبض السعودية" subtitle={subtitle} />
        <main className="px-10 pb-10 space-y-6">
          <div className="h-32 rounded-card shimmer" />
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="h-44 rounded-card shimmer" />
            ))}
          </div>
        </main>
      </>
    );
  }

  const compositeDir =
    data.composite_change_24h > 0 ? "up" :
    data.composite_change_24h < 0 ? "down" : "flat";

  async function copyEmbed() {
    const html = `<iframe src="${window.location.origin}/embed/index" width="100%" height="640" style="border:0;border-radius:24px"></iframe>`;
    try {
      await navigator.clipboard.writeText(html);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* ignore */
    }
  }

  return (
    <>
      <Header
        eyebrow="مؤشّر TRENDX اليومي"
        title="نبض السعودية"
        subtitle={subtitle}
        right={
          <div className="flex items-center gap-2">
            <Link
              href="/embed/index"
              target="_blank"
              className="inline-flex items-center gap-1.5 text-[11px] font-bold text-brand-600 bg-brand-50 hover:bg-brand-100 px-3 py-1.5 rounded-pill transition"
            >
              <ExternalLink size={12} /> النسخة العامّة
            </Link>
            <button
              type="button"
              onClick={copyEmbed}
              className="inline-flex items-center gap-1.5 text-[11px] font-bold text-ink-soft bg-canvas-well hover:bg-ink-line/40 px-3 py-1.5 rounded-pill transition"
            >
              <Copy size={12} /> {copied ? "تمّ نسخ الكود" : "نسخ كود التضمين"}
            </button>
          </div>
        }
      />
      <main className="flex-1 px-10 pb-10 space-y-7">
        {/* Composite hero */}
        <section className="bg-canvas-card rounded-card p-8 md:p-10 shadow-card-lift relative overflow-hidden">
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
              <div className="text-3xl font-display font-bold text-ink tabular">
                {fmtInt(data.total_responses)}
              </div>
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
              <div className="mt-4 h-1.5 bg-canvas-well rounded-pill overflow-hidden">
                <div
                  className="h-full bg-brand-gradient rounded-pill transition-all duration-700"
                  style={{ width: `${m.value}%` }}
                />
              </div>
            </article>
          ))}
        </section>
      </main>
    </>
  );
}

function DirectionIcon({ direction }: { direction: "up" | "down" | "flat" }) {
  if (direction === "up") return <TrendingUp size={18} className="text-positive" />;
  if (direction === "down") return <TrendingDown size={18} className="text-negative" />;
  return <Minus size={18} className="text-ink-mute" />;
}
