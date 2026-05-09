"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt } from "@/lib/format";

export default function SectorsListPage() {
  const { token } = useAuth();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);

  return (
    <>
      <Header
        title="القطاعات"
        subtitle="ذكاء قطاعي عابر للاستبيانات والاستطلاعات."
      />
      <main className="flex-1 px-9 py-6">
        {bootstrap.loading && (
          <div className="grid grid-cols-2 lg:grid-cols-3 gap-5">
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="h-44 rounded-card shimmer" />
            ))}
          </div>
        )}
        {bootstrap.data && (
          <div className="grid grid-cols-2 lg:grid-cols-3 gap-5">
            {bootstrap.data.topics.map((t) => {
              const pollsInTopic = bootstrap.data!.polls.filter((p) => p.topic_id === t.id);
              const surveysInTopic = bootstrap.data!.surveys.filter((s) => s.topic_id === t.id);
              const totalSignals = pollsInTopic.reduce((acc, p) => acc + p.total_votes, 0)
                + surveysInTopic.reduce((acc, s) => acc + s.total_responses, 0);
              return (
                <Link
                  key={t.id}
                  href={`/sectors/${t.id}`}
                  className="bg-canvas-card rounded-card shadow-card hover:shadow-card-hover transition p-5 group"
                >
                  <div className="flex items-center gap-3 mb-3">
                    <div
                      className="w-11 h-11 rounded-chip text-white grid place-items-center font-bold text-lg"
                      style={{ background: t.color }}
                    >
                      {t.icon}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="text-base font-bold text-ink group-hover:text-brand-600 transition">
                        {t.name}
                      </h3>
                      <p className="text-[11px] text-ink-mute">{t.slug}</p>
                    </div>
                  </div>
                  <div className="grid grid-cols-3 gap-2 pt-4 border-t border-ink-line">
                    <Stat label="استطلاعات" value={fmtInt(pollsInTopic.length)} />
                    <Stat label="استبيانات" value={fmtInt(surveysInTopic.length)} />
                    <Stat label="إشارات" value={fmtInt(totalSignals)} />
                  </div>
                </Link>
              );
            })}
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
      <div className="text-sm font-bold tabular text-ink mt-0.5">{value}</div>
    </div>
  );
}
