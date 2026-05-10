"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt, fmtPctRaw, fmtRelativeNow, fmtSeconds } from "@/lib/format";
import { ArrowLeft } from "lucide-react";

export default function SurveysListPage() {
  const { token } = useAuth();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);

  return (
    <>
      <Header
        eyebrow="SURVEYS"
        title="الاستبيانات"
        subtitle="استبيانات متعدّدة الأسئلة تكشف الأنماط الخفية والشخصيات الكامنة."
      />
      <main className="flex-1 px-10 pb-10">
        {bootstrap.loading && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {[0, 1, 2].map((i) => <div key={i} className="h-56 rounded-card shimmer" />)}
          </div>
        )}

        {bootstrap.data && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 stagger">
            {bootstrap.data.surveys.map((s, idx) => (
              <Link
                key={s.id}
                href={`/surveys/${s.id}`}
                className="group bg-canvas-card rounded-card shadow-card hover:shadow-card-lift transition-all duration-500 ease-soft p-8 relative overflow-hidden"
              >
                <div className="flex items-center justify-between mb-5">
                  <div className="flex items-center gap-2.5">
                    <span className="text-[10px] font-mono font-bold tabular text-ink-mute">
                      {String(idx + 1).padStart(2, "0")}
                    </span>
                    <span className="text-eyebrow text-brand-600">
                      {s.topic_name ?? "بدون قطاع"}
                    </span>
                  </div>
                  <span className="text-[10px] text-ink-mute">{fmtRelativeNow(s.created_at)}</span>
                </div>

                <h3 className="text-2xl font-display font-black text-ink leading-tight tracking-tight mb-3 group-hover:text-brand-600 transition">
                  {s.title}
                </h3>
                {s.description && (
                  <p className="text-[13px] text-ink-mute leading-relaxed mb-6 line-clamp-2 font-light">
                    {s.description}
                  </p>
                )}

                <div className="grid grid-cols-3 gap-6 pt-5 border-t border-ink-line/40">
                  <Stat label="مستجيب" value={fmtInt(s.total_responses)} tone="brand" />
                  <Stat label="معدل الإكمال" value={fmtPctRaw(s.completion_rate, 0)} tone="accent" />
                  <Stat label="وقت الإكمال" value={fmtSeconds(s.avg_completion_seconds)} tone="ai" />
                </div>

                <div className="absolute top-8 inset-inline-end-8 opacity-0 group-hover:opacity-100 transition flex items-center gap-1 text-[12px] font-bold text-brand-600">
                  Survey Intelligence <ArrowLeft size={13} />
                </div>
              </Link>
            ))}
          </div>
        )}

        {bootstrap.data && bootstrap.data.surveys.length === 0 && (
          <div className="bg-canvas-card rounded-card p-16 text-center text-ink-mute dotgrid">
            <p className="text-sm">لا توجد استبيانات بعد.</p>
          </div>
        )}
      </main>
    </>
  );
}

function Stat({ label, value, tone }: { label: string; value: string; tone: "brand" | "accent" | "ai" }) {
  const color =
    tone === "brand"   ? "text-brand-600" :
    tone === "accent"   ? "text-accent-700" :
    "text-ai-700";
  return (
    <div>
      <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute">{label}</div>
      <div className={`text-2xl font-display font-black tabular ${color} mt-1.5 leading-none`}>{value}</div>
    </div>
  );
}
