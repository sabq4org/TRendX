"use client";

import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt } from "@/lib/format";
import { Target, Trophy, TrendingUp } from "lucide-react";

export default function AccuracyPage() {
  const { token, user } = useAuth();
  const me = useFetch((t) => api.myAccuracy(t), token);
  const board = useFetch((t) => api.accuracyLeaderboard(t, 25), token);

  return (
    <>
      <Header
        eyebrow="PREDICTIVE ACCURACY"
        title="دقّة التنبّؤ"
        subtitle="حدسك في الرأي العامّ قابل للقياس — تابع تحسّنك مقارنةً بالمشاركين."
      />
      <main className="flex-1 px-10 pb-10 space-y-7">
        {/* Personal stats */}
        <section className="bg-canvas-card rounded-card p-8 shadow-card-lift relative overflow-hidden">
          <div className="absolute inset-0 bg-hero opacity-50 pointer-events-none" />
          <div className="relative">
            <div className="flex items-center gap-2 mb-4">
              <Target size={16} className="text-brand-500" />
              <span className="text-eyebrow text-brand-600">إحصائيّاتك</span>
            </div>
            {me.loading ? (
              <div className="h-32 rounded-chip shimmer" />
            ) : me.data ? (
              <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                <Stat label="متوسّط الدقّة" value={`${me.data.average_accuracy}/100`} accent="brand" />
                <Stat label="أفضل دقّة" value={`${me.data.best_accuracy}/100`} accent="ai" />
                <Stat label="إجمالي التنبّؤات" value={fmtInt(me.data.predictions)} />
                <Stat label="ترتيبك المئوي" value={me.data.rank_percentile > 0 ? `أعلى من ${me.data.rank_percentile}%` : "—"} accent="accent" />
              </div>
            ) : null}
          </div>
        </section>

        {/* Leaderboard */}
        <section className="bg-canvas-card rounded-card p-7 shadow-card">
          <div className="flex items-center gap-2 mb-5">
            <Trophy size={16} className="text-accent-500" />
            <span className="text-eyebrow text-accent-700">لوحة الشرف — أكثر المتنبّئين دقّة</span>
          </div>
          {board.loading ? (
            <div className="h-40 rounded-chip shimmer" />
          ) : board.data && board.data.items.length > 0 ? (
            <ul className="divide-y divide-ink-hairline">
              {board.data.items.map((it, i) => (
                <li key={it.user_id} className="py-3 flex items-center gap-4">
                  <span className={
                    i === 0 ? "w-8 h-8 grid place-items-center rounded-full bg-accent-500 text-canvas-card font-display font-bold text-sm" :
                    i === 1 ? "w-8 h-8 grid place-items-center rounded-full bg-ink-soft text-canvas-card font-display font-bold text-sm" :
                    i === 2 ? "w-8 h-8 grid place-items-center rounded-full bg-accent-300 text-ink font-display font-bold text-sm" :
                    "w-8 h-8 grid place-items-center text-sm font-display font-bold text-ink-mute tabular"
                  }>
                    {i + 1}
                  </span>
                  <span className="w-9 h-9 rounded-full bg-brand-50 grid place-items-center text-brand-700 font-display font-bold text-sm">
                    {it.avatar_initial}
                  </span>
                  <span className={
                    it.user_id === user?.id
                      ? "flex-1 font-display font-bold text-sm text-brand-700"
                      : "flex-1 font-display font-semibold text-sm text-ink"
                  }>
                    {it.name}
                    {it.user_id === user?.id && <span className="ms-2 text-[10px] font-bold text-brand-500">أنت</span>}
                  </span>
                  <span className="text-[11px] text-ink-mute tabular">{fmtInt(it.predictions)} تنبّؤ</span>
                  <span className="font-display font-bold tabular text-ink-soft">
                    {it.average_accuracy}<span className="text-[11px] text-ink-mute">/100</span>
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-ink-mute">لا يوجد تنبّؤات مسجَّلة بعد.</p>
          )}
        </section>

        <div className="text-[12px] text-ink-mute leading-relaxed">
          <TrendingUp size={12} className="inline mb-0.5 me-1" />
          الدقّة تُحسب لحظة إغلاق الاستطلاع: <b>100 - |تخمينك - النسبة الحقيقيّة|</b>.
          مثال: لو تنبّأت بـ 60% والنسبة الفعليّة كانت 67% → دقّتك 93/100.
        </div>
      </main>
    </>
  );
}

function Stat({
  label, value, accent,
}: { label: string; value: string; accent?: "brand" | "accent" | "ai" }) {
  const tone =
    accent === "brand" ? "text-brand-600" :
    accent === "accent" ? "text-accent-700" :
    accent === "ai" ? "text-ai-700" :
    "text-ink";
  return (
    <div>
      <div className="text-eyebrow text-ink-mute mb-1">{label}</div>
      <div className={`text-kpi-sm tabular ${tone}`}>{value}</div>
    </div>
  );
}
