"use client";

import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt } from "@/lib/format";
import {
  Activity,
  Apple,
  Clock,
  Info,
  Sparkles,
  Trophy,
  Users,
} from "lucide-react";
import clsx from "clsx";

/**
 * Pulse — read-only analytics view for the publisher dashboard.
 *
 * The actual voting only happens inside the iOS app. Showing the
 * voting form here would let publishers (and admins) skew the
 * national signal, so this page focuses on:
 *
 *   1. Today's question + live tallies
 *   2. Yesterday's AI summary
 *   3. The 14-day pulse history
 *
 * No POSTs are made from this page.
 */
export default function PulsePage() {
  const { token } = useAuth();
  const today = useFetch((t) => api.pulseTodayAnon(t), token);
  const yesterday = useFetch((t) => api.pulseYesterday(t), token);
  const history = useFetch((t) => api.pulseHistory(t, 14), token);

  if (today.loading) {
    return (
      <>
        <Header
          eyebrow="نبض اليوم"
          title="نبض السعودية اليوم"
          subtitle="بانتظار سؤال اليوم…"
        />
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
  const closesAt = new Date(t.closes_at).toLocaleTimeString("ar-SA", {
    hour: "2-digit",
    minute: "2-digit",
  });

  return (
    <>
      <Header
        eyebrow="نبض اليوم"
        title={t.question}
        subtitle={`سؤال اليوم — ${t.pulse_date} · يغلق الساعة ${closesAt}`}
      />
      <main className="flex-1 px-10 pb-10 space-y-7">
        {/* Read-only notice */}
        <div className="flex items-start gap-3 bg-ai-50/60 border border-ai-100 rounded-chip px-5 py-4">
          <Apple size={18} className="text-ai-700 mt-0.5 shrink-0" />
          <div className="flex-1 text-sm">
            <p className="font-display font-bold text-ai-700">
              التصويت متاح حصراً عبر تطبيق TRENDX على iOS
            </p>
            <p className="text-[12.5px] text-ink-soft mt-1 leading-relaxed">
              تُعرض هنا نتائج النبض اليومي للقراءة والتحليل فقط، حتى تظلّ
              الإشارة الوطنية ممثّلة لجمهور التطبيق وغير متأثّرة بأصوات
              الناشرين أو فريق المنصّة.
            </p>
          </div>
        </div>

        {/* Top row: total + closes-at + leading option */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 stagger">
          <StatChip
            icon={<Users size={18} className="text-brand-500" />}
            label="المشاركون اليوم"
            value={fmtInt(t.total_responses)}
            sub="حتّى الآن"
          />
          <StatChip
            icon={<Clock size={18} className="text-ai-500" />}
            label="إغلاق التصويت"
            value={closesAt}
            sub="بتوقيت السعودية"
          />
          <StatChip
            icon={<Trophy size={18} className="text-accent-500" />}
            label="الخيار الأعلى"
            value={leadingLabel(t.options)}
            sub={leadingPctLabel(t.options, t.total_responses)}
          />
        </div>

        {/* Today's pulse — bars only, no voting */}
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
            <ResultsBars
              options={t.options}
              total={t.total_responses}
            />
            {t.total_responses === 0 && (
              <p className="mt-5 text-[12px] text-ink-mute">
                لم تُسجّل أصوات بعد — ستبدأ النتائج في الظهور خلال الدقائق القليلة المقبلة.
              </p>
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
          <div className="flex items-center gap-2 mb-4">
            <h3 className="text-lg font-display font-bold text-ink">آخر 14 يوم</h3>
            <Info size={14} className="text-ink-mute" />
          </div>
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
                  <span className="text-[11px] text-ink-mute">
                    {fmtInt(h.total_responses)} مشارك
                  </span>
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

type Option = { index: number; text: string; votes: number; percentage: number };

function leadingLabel(options: Option[]): string {
  if (options.length === 0) return "—";
  const top = [...options].sort((a, b) => b.votes - a.votes)[0];
  return top.text;
}

function leadingPctLabel(options: Option[], total: number): string {
  if (options.length === 0 || total === 0) return "—";
  const top = [...options].sort((a, b) => b.votes - a.votes)[0];
  return `${top.percentage}% من الأصوات`;
}

function StatChip({
  icon,
  label,
  value,
  sub,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  sub: string;
}) {
  return (
    <div className="bg-canvas-card rounded-card p-5 shadow-card flex items-center gap-4">
      <div className="w-11 h-11 grid place-items-center rounded-chip bg-canvas-well">
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-[10px] font-bold uppercase tracking-[0.16em] text-ink-mute">
          {label}
        </div>
        <div className="text-xl font-display font-bold text-ink tabular leading-tight truncate">
          {value}
        </div>
        <div className="text-[11px] text-ink-mute">{sub}</div>
      </div>
    </div>
  );
}

function ResultsBars({
  options,
  total,
}: {
  options: Option[];
  total: number;
}) {
  return (
    <div className="space-y-3">
      {options.map((o) => {
        const winning = options.every((x) => x.votes <= o.votes) && total > 5;
        return (
          <div key={o.index} className="relative">
            <div className="flex items-center justify-between mb-1.5">
              <span
                className={clsx(
                  "font-display font-semibold text-sm",
                  winning ? "text-accent-700" : "text-ink",
                )}
              >
                {o.text}
                {winning && (
                  <span className="ms-2 inline-flex items-center gap-1 text-[10px] font-bold text-accent-700">
                    <Trophy size={11} /> الأعلى
                  </span>
                )}
              </span>
              <span className="text-sm font-display font-bold tabular text-ink">
                {o.percentage}%{" "}
                <span className="text-[11px] text-ink-mute font-normal">
                  ({fmtInt(o.votes)})
                </span>
              </span>
            </div>
            <div className="h-2.5 bg-canvas-well rounded-pill overflow-hidden">
              <div
                className={clsx(
                  "h-full rounded-pill transition-all duration-700",
                  winning ? "bg-accent-500" : "bg-brand-gradient",
                )}
                style={{ width: `${o.percentage}%` }}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
}
