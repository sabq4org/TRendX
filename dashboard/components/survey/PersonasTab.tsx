"use client";

import { useEffect, useState } from "react";
import { Sparkles, Users, MapPin, Calendar } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { fmtInt, genderLabel } from "@/lib/format";
import type { SurveyPersonas } from "@/lib/types";

const TONE_BG = ["bg-brand-50", "bg-accent-50", "bg-ai-50", "bg-positive-soft", "bg-warning-soft"];
const TONE_TEXT = ["text-brand-600", "text-accent-700", "text-ai-700", "text-positive", "text-warning"];

export function SurveyPersonasTab({ surveyId }: { surveyId: string }) {
  const { token } = useAuth();
  const [data, setData] = useState<SurveyPersonas | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  async function load(force = false) {
    if (!token) return;
    setLoading(!data);
    setRefreshing(force);
    setError(null);
    try {
      const result = await api.surveyPersonas(token, surveyId, force);
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    void load(false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token, surveyId]);

  if (loading) {
    return (
      <div className="bg-canvas-card rounded-card p-16 text-center">
        <div className="w-10 h-10 mx-auto rounded-full border-2 border-ink-line border-t-brand-500 animate-spin mb-4" />
        <p className="text-sm text-ink-mute">يتم اكتشاف الشخصيّات عبر k-medoids + GPT-4o…</p>
      </div>
    );
  }

  if (error) {
    return <div className="bg-canvas-card rounded-card p-12 text-center text-negative text-sm">{error}</div>;
  }

  if (!data || data.personas.length === 0) {
    return (
      <div className="bg-canvas-card rounded-card p-16 text-center dotgrid">
        <Users size={32} className="mx-auto text-ink-ghost mb-4" />
        <p className="text-sm text-ink-mute">لا تتوفّر عيّنة كافية لاكتشاف الشخصيّات بعد.</p>
        <p className="text-xs text-ink-ghost mt-1.5">نحتاج 6 مستجيبين على الأقل أكملوا الاستبيان.</p>
      </div>
    );
  }

  return (
    <div className="space-y-5 stagger">
      <div className="bg-canvas-card rounded-card shadow-card p-6 flex items-center justify-between">
        <div>
          <div className="text-eyebrow text-brand-600 mb-1">PERSONAS DETECTED</div>
          <h3 className="text-base font-display font-bold text-ink tracking-tight">
            {data.k} شخصيّات مكتشفة من {fmtInt(data.sample_size)} مستجيب مكتمل
          </h3>
          <p className="text-[11px] text-ink-mute mt-1 font-mono">
            {data.model} • {data.prompt_version} • {data.cached ? "من الكاش" : "تم التوليد للتوّ"}
          </p>
        </div>
        <button
          onClick={() => load(true)}
          disabled={refreshing}
          className="text-[11px] font-bold px-3 py-2 rounded-chip border border-ink-line hover:border-brand-500 hover:text-brand-600 disabled:opacity-50 transition flex items-center gap-1.5"
        >
          <Sparkles size={12} />
          {refreshing ? "جارٍ التحديث…" : "إعادة التوليد"}
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-5">
        {data.personas.map((p, i) => {
          const bg = TONE_BG[i % TONE_BG.length];
          const txt = TONE_TEXT[i % TONE_TEXT.length];
          return (
            <article
              key={p.cluster_index}
              className="bg-canvas-card rounded-card shadow-card overflow-hidden hover:shadow-card-lift transition-shadow duration-500 ease-soft"
            >
              <div className={`${bg} p-6`}>
                <div className="flex items-baseline justify-between gap-3 mb-3">
                  <span className="text-[10px] font-mono font-bold tabular text-ink-mute">
                    P{String(i + 1).padStart(2, "0")}
                  </span>
                  <span className={`font-display font-black tabular text-3xl ${txt} tracking-tight leading-none`}>
                    {p.share_pct}<span className="text-base text-ink-mute font-medium">%</span>
                  </span>
                </div>
                <h3 className="text-2xl font-display font-black text-ink tracking-tight leading-tight mb-2">
                  {p.name}
                </h3>
                <div className="text-[12px] text-ink-mute">
                  {fmtInt(p.size)} مستجيب
                </div>
              </div>

              <div className="p-6 space-y-5">
                <p className="text-[13px] text-ink-soft leading-relaxed font-light">
                  {p.description}
                </p>

                {p.traits.length > 0 && (
                  <div className="flex flex-wrap gap-1.5">
                    {p.traits.map((trait, j) => (
                      <span
                        key={j}
                        className={`text-[10px] font-bold px-2.5 py-1 rounded-pill ${bg} ${txt}`}
                      >
                        {trait}
                      </span>
                    ))}
                  </div>
                )}

                {p.representative_quote && (
                  <div className="border-s-2 border-brand-300 ps-4 py-1">
                    <p className="text-[12px] text-ink italic leading-relaxed font-light">
                      «{p.representative_quote}»
                    </p>
                  </div>
                )}

                <div className="grid grid-cols-3 gap-3 pt-4 border-t border-ink-line/40">
                  <DemoChip icon={Users} label="جنس" value={p.dominant_gender ? genderLabel(p.dominant_gender) : "—"} />
                  <DemoChip icon={Calendar} label="عمر" value={p.dominant_age_group ?? "—"} />
                  <DemoChip icon={MapPin} label="مدينة" value={p.dominant_city ?? "—"} />
                </div>

                {p.modal_answers.length > 0 && (
                  <details className="group">
                    <summary className="cursor-pointer text-[11px] font-bold uppercase tracking-[0.14em] text-ink-mute hover:text-brand-600 transition">
                      الإجابات السائدة ({p.modal_answers.length})
                    </summary>
                    <ul className="mt-3 space-y-2.5">
                      {p.modal_answers.map((a, k) => (
                        <li key={k} className="text-[12px] leading-relaxed">
                          <div className="text-ink-mute line-clamp-1">{a.question_title}</div>
                          <div className="text-ink font-medium mt-0.5">→ {a.option_text}</div>
                        </li>
                      ))}
                    </ul>
                  </details>
                )}
              </div>
            </article>
          );
        })}
      </div>
    </div>
  );
}

function DemoChip({
  icon: Icon, label, value,
}: { icon: typeof Users; label: string; value: string }) {
  return (
    <div className="text-center">
      <Icon size={12} className="mx-auto text-ink-ghost mb-1" />
      <div className="text-[9px] font-bold uppercase tracking-[0.14em] text-ink-mute">{label}</div>
      <div className="text-[12px] font-semibold text-ink mt-0.5 truncate">{value}</div>
    </div>
  );
}
