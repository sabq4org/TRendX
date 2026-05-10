"use client";

import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { Sparkles, RefreshCw, Share2 } from "lucide-react";
import { useState } from "react";

export default function DNAPage() {
  const { token } = useAuth();
  const dna = useFetch((t) => api.myDNA(t).catch((e) => { throw e; }), token);
  const [refreshing, setRefreshing] = useState(false);

  async function refresh() {
    if (!token) return;
    setRefreshing(true);
    try {
      await api.refreshDNA(token);
      dna.refresh();
    } catch (err) {
      alert(err instanceof Error ? err.message : String(err));
    } finally {
      setRefreshing(false);
    }
  }

  function copyShare() {
    if (!dna.data) return;
    void navigator.clipboard.writeText(dna.data.share_caption);
    alert("تم نسخ نصّ المشاركة 🎉");
  }

  return (
    <>
      <Header
        eyebrow="OPINION DNA"
        title="هويّتك في الرأي"
        subtitle="ست محاور تقيس هويّتك الفكريّة بناءً على تصويتاتك على TRENDX."
        right={
          <div className="flex items-center gap-2">
            <button
              onClick={refresh}
              disabled={refreshing}
              className="inline-flex items-center gap-1.5 text-[11px] font-bold px-3 py-2 rounded-chip border border-ink-line hover:border-brand-500 hover:text-brand-600 transition disabled:opacity-50"
            >
              <RefreshCw size={12} className={refreshing ? "animate-spin" : ""} /> تحديث
            </button>
            <button
              onClick={copyShare}
              disabled={!dna.data}
              className="inline-flex items-center gap-1.5 text-[11px] font-bold px-3 py-2 rounded-chip bg-ai-500 text-canvas-card hover:bg-ai-700 transition disabled:opacity-50"
            >
              <Share2 size={12} /> شارك
            </button>
          </div>
        }
      />
      <main className="flex-1 px-10 pb-10 space-y-7 max-w-5xl">
        {dna.loading ? (
          <div className="h-96 rounded-card shimmer" />
        ) : dna.error || !dna.data ? (
          <div className="bg-canvas-card rounded-card p-10 text-center">
            <Sparkles size={32} className="mx-auto mb-3 text-ai-500" />
            <h2 className="text-xl font-display font-bold text-ink mb-2">
              لم تكتمل هويّتك بعد
            </h2>
            <p className="text-sm text-ink-soft max-w-md mx-auto">
              شارك في 3 استطلاعات أو نبضات يوميّة على الأقلّ لنبني هويّتك الفكريّة الكاملة.
            </p>
          </div>
        ) : (
          <>
            {/* Archetype hero */}
            <section className="glass-ai rounded-card p-10 relative overflow-hidden">
              <div className="absolute inset-0 dotgrid opacity-20 pointer-events-none" />
              <div className="relative">
                <div className="flex items-center gap-2 mb-3">
                  <Sparkles size={16} className="text-ai-500" />
                  <span className="text-eyebrow text-ai-700">شخصيّتك في الرأي</span>
                </div>
                <h1 className="text-5xl md:text-7xl font-display font-black ai-text-gradient leading-none mb-4">
                  {dna.data.archetype.title}
                </h1>
                <p className="text-base md:text-lg text-ink-soft leading-relaxed max-w-2xl">
                  {dna.data.archetype.blurb}
                </p>
                <div className="text-[11px] text-ink-mute tabular mt-5">
                  استناداً إلى {dna.data.sample_size} تصويت ·
                  محسوبة في {new Date(dna.data.computed_at).toLocaleString("ar-SA", { dateStyle: "medium", timeStyle: "short" })}
                </div>
              </div>
            </section>

            {/* Axes */}
            <section className="grid grid-cols-1 md:grid-cols-2 gap-5 stagger">
              {dna.data.axes.map((a) => {
                const tilt = a.score - 50; // -50..+50
                const sideLabel = tilt > 0 ? a.label_high : a.label_low;
                const intensity = Math.abs(tilt) >= 25 ? "قوي" : Math.abs(tilt) >= 10 ? "معتدل" : "متوازن";
                return (
                  <article
                    key={a.key}
                    className="bg-canvas-card rounded-card p-6 shadow-card hover:shadow-card-lift transition-all"
                  >
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-eyebrow text-ai-700">{intensity}</span>
                      <span className="text-[11px] font-bold text-ink-mute tabular">
                        {a.score}/100
                      </span>
                    </div>
                    <div className="text-2xl font-display font-bold text-ink leading-tight mb-3">
                      {sideLabel}
                    </div>

                    {/* Bipolar bar */}
                    <div className="relative h-3 bg-canvas-well rounded-pill overflow-hidden">
                      <div
                        className="absolute top-0 bottom-0 bg-ai-gradient rounded-pill transition-all duration-700"
                        style={
                          tilt >= 0
                            ? { left: "50%", width: `${Math.abs(tilt)}%` }
                            : { right: "50%", width: `${Math.abs(tilt)}%` }
                        }
                      />
                      {/* Mid divider */}
                      <div className="absolute top-0 bottom-0 left-1/2 w-px bg-ink-line" />
                    </div>
                    <div className="flex justify-between mt-2 text-[11px] text-ink-mute font-medium">
                      <span>{a.label_low}</span>
                      <span>{a.label_high}</span>
                    </div>
                  </article>
                );
              })}
            </section>

            {/* Share caption */}
            <section className="bg-ai-50/40 rounded-card p-6 border border-ai-100">
              <div className="text-eyebrow text-ai-700 mb-2">جملة المشاركة</div>
              <p className="text-base text-ink leading-relaxed">«{dna.data.share_caption}»</p>
            </section>
          </>
        )}
      </main>
    </>
  );
}
