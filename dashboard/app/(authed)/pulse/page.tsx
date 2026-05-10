"use client";

import { useState } from "react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt } from "@/lib/format";
import { Activity, Clock, Flame, Sparkles, Trophy, Users, Zap } from "lucide-react";
import clsx from "clsx";

export default function PulsePage() {
  const { token } = useAuth();
  const today = useFetch((t) => api.pulseToday(t), token);
  const yesterday = useFetch((t) => api.pulseYesterday(t), token);
  const history = useFetch((t) => api.pulseHistory(t, 14), token);
  const streak = useFetch((t) => api.myStreak(t), token);

  const [picked, setPicked] = useState<number | null>(null);
  const [predicted, setPredicted] = useState<number>(50);
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<{
    reward: number;
    streak: { current_streak: number; is_personal_best?: boolean; delta?: string };
    prediction_score: number | null;
  } | null>(null);

  if (today.loading) {
    return (
      <>
        <Header eyebrow="نبض اليوم" title="نبض السعودية اليوم" subtitle="بانتظار سؤال اليوم…" />
        <main className="px-10 pb-10">
          <div className="h-72 rounded-card shimmer" />
        </main>
      </>
    );
  }
  if (today.error || !today.data) {
    return (
      <>
        <Header eyebrow="نبض اليوم" title="نبض السعودية اليوم" />
        <main className="px-10 pb-10">
          <div className="bg-canvas-card rounded-card p-8 text-negative">
            تعذّر جلب نبض اليوم: {today.error}
          </div>
        </main>
      </>
    );
  }

  const t = today.data;
  const hasResponded = t.user_responded === true;
  const winning = [...t.options].sort((a, b) => b.votes - a.votes)[0];

  async function submit() {
    if (picked === null || !token) return;
    setSubmitting(true);
    try {
      const r = await api.pulseRespond(token, { option_index: picked, predicted_pct: predicted });
      setResult({ reward: r.reward, streak: r.streak, prediction_score: r.prediction_score });
      today.refresh();
      yesterday.refresh();
      streak.refresh();
    } catch (err) {
      alert(err instanceof Error ? err.message : String(err));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <>
      <Header
        eyebrow="نبض اليوم"
        title={t.question}
        subtitle={`سؤال اليوم — ${t.pulse_date} · يغلق الساعة ${new Date(t.closes_at).toLocaleTimeString("ar-SA", { hour: "2-digit", minute: "2-digit" })}`}
      />
      <main className="flex-1 px-10 pb-10 space-y-7">
        {/* Top row: streak + total responses + closes-at */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 stagger">
          <StatChip
            icon={<Flame size={18} className="text-accent-500" />}
            label="سلسلة المشاركة"
            value={streak.data ? `${streak.data.current_streak} يوم` : "—"}
            sub={streak.data && streak.data.longest_streak > 0 ? `أطول سلسلة: ${streak.data.longest_streak}` : "ابدأ سلسلتك اليوم"}
          />
          <StatChip
            icon={<Users size={18} className="text-brand-500" />}
            label="المشاركون اليوم"
            value={fmtInt(t.total_responses)}
            sub="حتّى الآن"
          />
          <StatChip
            icon={<Clock size={18} className="text-ai-500" />}
            label="مكافأة المشاركة"
            value={`${t.reward_points} نقطة`}
            sub={(streak.data?.current_streak ?? 0) > 0 ? `+ مكافأة سلسلة` : "بمجرد التصويت"}
          />
        </div>

        {/* Today's pulse card */}
        <section className="bg-canvas-card rounded-card p-8 shadow-card-lift relative overflow-hidden">
          <div className="absolute inset-0 bg-hero opacity-50 pointer-events-none" />
          <div className="relative">
            <div className="flex items-center gap-2 mb-2">
              <Activity size={16} className="text-brand-500" />
              <span className="text-eyebrow text-brand-600">السؤال اليومي</span>
            </div>
            <h2 className="text-2xl md:text-3xl font-display font-bold text-ink leading-snug mb-6">
              {t.question}
            </h2>

            {!hasResponded && !result && (
              <>
                <div className="space-y-3 mb-6">
                  {t.options.map((o) => {
                    const active = picked === o.index;
                    return (
                      <button
                        key={o.index}
                        onClick={() => setPicked(o.index)}
                        className={clsx(
                          "w-full text-right px-5 py-4 rounded-chip border transition flex items-center justify-between",
                          active
                            ? "border-brand-500 bg-brand-50 shadow-glow"
                            : "border-ink-line hover:border-brand-300 hover:bg-canvas-well/50",
                        )}
                      >
                        <span className="font-display font-semibold text-ink">{o.text}</span>
                        <span
                          className={clsx(
                            "w-5 h-5 rounded-full grid place-items-center transition",
                            active ? "bg-brand-500" : "border-2 border-ink-line",
                          )}
                        >
                          {active && <span className="w-2 h-2 rounded-full bg-canvas-card" />}
                        </span>
                      </button>
                    );
                  })}
                </div>

                {/* Prediction game */}
                <div className="mt-6 p-5 rounded-chip bg-ai-50/40 border border-ai-100">
                  <div className="flex items-center gap-2 mb-2">
                    <Target size={16} className="text-ai-700" />
                    <span className="text-eyebrow text-ai-700">لعبة التنبّؤ — اختياري</span>
                  </div>
                  <p className="text-sm text-ink-soft mb-3">
                    كم نسبة من تتوقّع أن يختار <b>الخيار الأكثر تصويتاً</b>؟
                  </p>
                  <div className="flex items-center gap-4">
                    <input
                      type="range"
                      min="0"
                      max="100"
                      value={predicted}
                      onChange={(e) => setPredicted(Number(e.target.value))}
                      className="flex-1 accent-ai-500"
                    />
                    <span className="font-display font-bold text-2xl tabular text-ai-700 min-w-[64px] text-center">
                      {predicted}%
                    </span>
                  </div>
                  <p className="text-[11px] text-ink-mute mt-2">
                    تخمينك يضاف لرصيد دقّتك التراكمي.
                  </p>
                </div>

                <button
                  onClick={submit}
                  disabled={picked === null || submitting}
                  className="mt-6 w-full brand-fill disabled:opacity-50 disabled:cursor-not-allowed font-bold py-4 rounded-chip text-base shadow-card hover:shadow-glow transition"
                >
                  {submitting ? "جارِ الإرسال…" : "أرسل صوتي"}
                </button>
              </>
            )}

            {(hasResponded || result) && (
              <ResultsPanel
                pulse={t}
                myChoice={result ? picked! : (t.user_choice ?? -1)}
                reward={result?.reward}
                streak={result?.streak}
                predictionScore={result?.prediction_score ?? null}
              />
            )}
          </div>
        </section>

        {/* Yesterday's AI summary */}
        {yesterday.data?.pulse && (
          <section className="glass-ai rounded-card p-7">
            <div className="flex items-center gap-2 mb-2">
              <Sparkles size={16} className="text-ai-500" />
              <span className="text-eyebrow text-ai-700">نبض الأمس</span>
            </div>
            <h3 className="text-lg font-display font-bold text-ink mb-3">
              {yesterday.data.pulse.question}
            </h3>
            {yesterday.data.pulse.ai_summary ? (
              <p className="text-sm leading-relaxed text-ink-soft">
                {yesterday.data.pulse.ai_summary}
              </p>
            ) : (
              <p className="text-sm text-ink-mute">— التحليل قيد التحضير —</p>
            )}
            <div className="mt-4 grid grid-cols-2 md:grid-cols-4 gap-3">
              {yesterday.data.pulse.options.map((o) => (
                <div key={o.index} className="bg-canvas-card/70 rounded-chip p-3">
                  <div className="text-[11px] text-ink-mute font-bold">{o.text}</div>
                  <div className="text-2xl font-display font-bold text-ai-700 tabular mt-1">
                    {o.percentage}%
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Pulse history mini-list */}
        <section className="bg-canvas-card rounded-card p-7 shadow-card">
          <h3 className="text-lg font-display font-bold text-ink mb-4">آخر 14 يوم</h3>
          {history.loading ? (
            <div className="h-24 rounded-chip shimmer" />
          ) : history.data && history.data.items.length > 0 ? (
            <ul className="divide-y divide-ink-hairline">
              {history.data.items.map((h) => (
                <li key={h.pulse_date} className="py-3 flex items-center gap-4">
                  <span className="text-[11px] font-bold text-ink-mute tabular w-20">
                    {h.pulse_date.slice(5)}
                  </span>
                  <span className="flex-1 text-sm text-ink truncate">{h.question}</span>
                  <span className="text-[11px] text-ink-mute">{fmtInt(h.total_responses)} مشارك</span>
                  {h.leading_option_text && (
                    <span className="text-[11px] font-bold text-brand-600 bg-brand-50 px-2 py-0.5 rounded-pill tabular">
                      {h.leading_pct}% — {h.leading_option_text}
                    </span>
                  )}
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-ink-mute">لا يوجد سجلّ بعد.</p>
          )}
        </section>
      </main>
    </>
  );
}

function StatChip({
  icon, label, value, sub,
}: { icon: React.ReactNode; label: string; value: string; sub: string }) {
  return (
    <div className="bg-canvas-card rounded-card p-5 shadow-card flex items-center gap-4">
      <div className="w-11 h-11 grid place-items-center rounded-chip bg-canvas-well">
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-[10px] font-bold uppercase tracking-[0.16em] text-ink-mute">{label}</div>
        <div className="text-xl font-display font-bold text-ink tabular leading-tight">{value}</div>
        <div className="text-[11px] text-ink-mute">{sub}</div>
      </div>
    </div>
  );
}

function Target({ size, className }: { size: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className={className}>
      <circle cx="12" cy="12" r="10" />
      <circle cx="12" cy="12" r="6" />
      <circle cx="12" cy="12" r="2" />
    </svg>
  );
}

function ResultsPanel({
  pulse, myChoice, reward, streak, predictionScore,
}: {
  pulse: { options: Array<{ index: number; text: string; votes: number; percentage: number }>; total_responses: number };
  myChoice: number;
  reward?: number;
  streak?: { current_streak: number; is_personal_best?: boolean; delta?: string };
  predictionScore: number | null;
}) {
  return (
    <>
      {(reward !== undefined || streak) && (
        <div className="mb-5 p-5 rounded-chip bg-positive/10 border border-positive/30 flex items-center gap-4 animate-scale-in">
          <Zap size={22} className="text-positive" />
          <div className="flex-1">
            <div className="text-base font-display font-bold text-positive">شُكراً لمشاركتك! </div>
            <div className="text-sm text-ink-soft">
              {reward !== undefined && <>+{reward} نقطة · </>}
              {streak && (
                <>
                  سلسلة <b>{streak.current_streak}</b> يوم
                  {streak.is_personal_best ? " 🏆 رقم قياسي شخصي" : ""}
                </>
              )}
              {predictionScore !== null && (
                <> · دقّة تنبّؤك: <b className="text-ai-700">{predictionScore}/100</b></>
              )}
            </div>
          </div>
        </div>
      )}
      <div className="space-y-3">
        {pulse.options.map((o) => {
          const mine = o.index === myChoice;
          const winning = pulse.options.every((x) => x.votes <= o.votes);
          return (
            <div key={o.index} className="relative">
              <div className="flex items-center justify-between mb-1.5">
                <span className={clsx("font-display font-semibold text-sm", mine ? "text-brand-600" : "text-ink")}>
                  {o.text}
                  {mine && <span className="ms-2 text-[10px] font-bold text-brand-500">صوتك</span>}
                  {winning && pulse.total_responses > 5 && (
                    <span className="ms-2 inline-flex items-center gap-1 text-[10px] font-bold text-accent-700">
                      <Trophy size={11} /> الأعلى
                    </span>
                  )}
                </span>
                <span className="text-sm font-display font-bold tabular text-ink">
                  {o.percentage}% <span className="text-[11px] text-ink-mute font-normal">({fmtInt(o.votes)})</span>
                </span>
              </div>
              <div className="h-2.5 bg-canvas-well rounded-pill overflow-hidden">
                <div
                  className={clsx(
                    "h-full rounded-pill transition-all duration-700",
                    mine ? "bg-brand-gradient" : winning ? "bg-accent-500" : "bg-ink-line",
                  )}
                  style={{ width: `${o.percentage}%` }}
                />
              </div>
            </div>
          );
        })}
      </div>
    </>
  );
}
