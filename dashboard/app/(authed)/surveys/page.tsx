"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt, fmtPctRaw, fmtRelativeNow, fmtSeconds } from "@/lib/format";

export default function SurveysListPage() {
  const { token } = useAuth();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);

  return (
    <>
      <Header
        title="الاستبيانات"
        subtitle="استبيانات متعدّدة الأسئلة تكشف الأنماط الخفية والشخصيات."
      />
      <main className="flex-1 px-9 py-6">
        {bootstrap.loading && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-48 rounded-card shimmer" />
            ))}
          </div>
        )}

        {bootstrap.data && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
            {bootstrap.data.surveys.map((s) => (
              <Link
                key={s.id}
                href={`/surveys/${s.id}`}
                className="bg-canvas-card rounded-card shadow-card hover:shadow-card-hover transition p-6 group"
              >
                <div className="flex items-center justify-between mb-3">
                  <span className="text-[10px] font-bold uppercase tracking-wide text-ink-mute">
                    {s.topic_name ?? "بدون قطاع"}
                  </span>
                  <span className="text-[10px] text-ink-mute">{fmtRelativeNow(s.created_at)}</span>
                </div>

                <h3 className="text-lg font-bold text-ink leading-snug mb-2 group-hover:text-brand-600 transition">
                  {s.title}
                </h3>
                {s.description && (
                  <p className="text-xs text-ink-mute leading-relaxed mb-4 line-clamp-2">
                    {s.description}
                  </p>
                )}

                <div className="grid grid-cols-3 gap-3 pt-4 border-t border-ink-line">
                  <Stat label="مستجيب" value={fmtInt(s.total_responses)} />
                  <Stat label="معدل الإكمال" value={fmtPctRaw(s.completion_rate, 0)} />
                  <Stat label="وقت الإكمال" value={fmtSeconds(s.avg_completion_seconds)} />
                </div>

                <div className="mt-4 text-[11px] text-brand-600 font-bold flex items-center gap-1 group-hover:gap-2 transition-all">
                  افتح Survey Intelligence ←
                </div>
              </Link>
            ))}
          </div>
        )}

        {bootstrap.data && bootstrap.data.surveys.length === 0 && (
          <div className="bg-canvas-card rounded-card p-12 text-center text-ink-mute">
            لا توجد استبيانات بعد.
          </div>
        )}
      </main>
    </>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-[10px] font-semibold uppercase tracking-wide text-ink-mute">{label}</div>
      <div className="text-base font-bold tabular text-ink mt-0.5">{value}</div>
    </div>
  );
}
