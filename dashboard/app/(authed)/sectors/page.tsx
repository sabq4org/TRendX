"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt } from "@/lib/format";
import { ArrowLeft } from "lucide-react";

export default function SectorsListPage() {
  const { token } = useAuth();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);

  return (
    <>
      <Header
        eyebrow="SECTORS"
        title="القطاعات"
        subtitle="ذكاء قطاعي عابر للاستبيانات والاستطلاعات."
      />
      <main className="flex-1 px-10 pb-10">
        {bootstrap.loading && (
          <div className="grid grid-cols-2 lg:grid-cols-3 gap-6">
            {[0, 1, 2, 3, 4, 5].map((i) => <div key={i} className="h-48 rounded-card shimmer" />)}
          </div>
        )}
        {bootstrap.data && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 stagger">
            {bootstrap.data.topics.map((t, idx) => {
              const pollsInTopic = bootstrap.data!.polls.filter((p) => p.topic_id === t.id);
              const surveysInTopic = bootstrap.data!.surveys.filter((s) => s.topic_id === t.id);
              const totalSignals = pollsInTopic.reduce((acc, p) => acc + p.total_votes, 0)
                + surveysInTopic.reduce((acc, s) => acc + s.total_responses, 0);
              return (
                <Link
                  key={t.id}
                  href={`/sectors/${t.id}`}
                  className="group bg-canvas-card rounded-card shadow-card hover:shadow-card-lift transition-all duration-500 ease-soft p-7 relative overflow-hidden"
                >
                  <div className="flex items-center justify-between mb-5">
                    <span className="text-[10px] font-mono font-bold tabular text-ink-mute">
                      {String(idx + 1).padStart(2, "0")}
                    </span>
                    <ArrowLeft
                      size={14}
                      className="text-ink-ghost group-hover:text-sage-700 group-hover:-translate-x-1 transition-all"
                    />
                  </div>

                  <div className="text-eyebrow text-sage-700 mb-2">SECTOR</div>
                  <h3 className="text-3xl font-display font-black text-ink mb-1 tracking-tight group-hover:text-sage-700 transition leading-tight">
                    {t.name}
                  </h3>
                  <p className="text-[11px] text-ink-mute font-mono mb-6">{t.slug}</p>

                  <div className="grid grid-cols-3 gap-4 pt-5 border-t border-ink-line/40">
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
      <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute">{label}</div>
      <div className="text-xl font-display font-black tabular text-ink mt-1.5 leading-none">{value}</div>
    </div>
  );
}
