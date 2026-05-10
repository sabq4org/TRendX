"use client";

import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { Plus, ArrowLeft, Sparkles, Zap } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { Modal } from "@/components/Modal";
import { CreatePollModal } from "@/components/CreatePollModal";
import { fmtInt, fmtRelativeNow } from "@/lib/format";

export default function PollsListPage() {
  const { token, user } = useAuth();
  const router = useRouter();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);

  const [showCreate, setShowCreate] = useState(false);

  const canCreate = user?.role === "publisher" || user?.role === "admin";

  function handleCreated(pollId: string) {
    setShowCreate(false);
    bootstrap.refresh();
    router.push(`/polls/${pollId}`);
  }

  return (
    <>
      <Header
        eyebrow="POLLS"
        title="الاستطلاعات"
        subtitle={
          bootstrap.data
            ? `${fmtInt(bootstrap.data.polls.length)} استطلاعاً نشطاً تجمع ${fmtInt(bootstrap.data.polls.reduce((a, p) => a + p.total_votes, 0))} صوتاً.`
            : "بانتظار البيانات…"
        }
        right={
          canCreate ? (
            <button
              onClick={() => setShowCreate(true)}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-chip bg-brand-600 text-canvas-card text-[13px] font-bold shadow-card hover:bg-brand-700 transition"
            >
              <Plus size={15} />
              استطلاع جديد
            </button>
          ) : undefined
        }
      />
      <main className="flex-1 px-10 pb-10">
        {bootstrap.loading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="h-52 rounded-card shimmer" />
            ))}
          </div>
        )}

        {bootstrap.data && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 stagger">
            {bootstrap.data.polls.map((poll, idx) => {
              const leading = [...poll.options].sort((a, b) => b.votes_count - a.votes_count)[0];
              const leadingPct = poll.total_votes > 0 && leading
                ? Math.round((leading.votes_count / poll.total_votes) * 100)
                : 0;
              return (
                <Link
                  key={poll.id}
                  href={`/polls/${poll.id}`}
                  className="group bg-canvas-card rounded-card shadow-card hover:shadow-card-lift transition-all duration-500 ease-soft p-7 relative overflow-hidden"
                >
                  <div className="flex items-center justify-between mb-4">
                    <span className="text-[10px] font-mono font-bold tabular text-ink-mute">
                      {String(idx + 1).padStart(2, "0")}
                    </span>
                    <div className="flex items-center gap-1.5">
                      {poll.is_breaking && (
                        <span className="px-2 py-0.5 rounded-pill bg-negative-soft text-negative text-[10px] font-bold flex items-center gap-1">
                          <Zap size={9} /> عاجل
                        </span>
                      )}
                      {poll.is_featured && (
                        <span className="px-2 py-0.5 rounded-pill bg-accent-50 text-accent-700 text-[10px] font-bold flex items-center gap-1">
                          <Sparkles size={9} /> مميّز
                        </span>
                      )}
                      <span className="text-[10px] text-ink-mute">{fmtRelativeNow(poll.created_at)}</span>
                    </div>
                  </div>

                  <h3 className="text-lg font-display font-bold text-ink leading-snug mb-3 line-clamp-2 group-hover:text-brand-600 transition tracking-tight">
                    {poll.title}
                  </h3>

                  {poll.topic_name && (
                    <span className="inline-block px-2.5 py-1 rounded-pill bg-canvas-well text-[10px] font-bold uppercase tracking-[0.1em] text-ink-soft mb-4">
                      {poll.topic_name}
                    </span>
                  )}

                  {leading && (
                    <div className="space-y-1.5 mb-5">
                      <div className="flex items-baseline justify-between">
                        <span className="text-[12px] font-medium text-ink-soft truncate me-3">
                          {leading.text}
                        </span>
                        <span className="font-display font-black tabular text-2xl text-brand-600 leading-none">
                          {leadingPct}<span className="text-[12px] font-medium text-ink-mute">%</span>
                        </span>
                      </div>
                      <div className="h-1.5 rounded-pill bg-canvas-well overflow-hidden">
                        <div
                          className="h-full bg-brand-600 transition-all duration-700 ease-soft"
                          style={{ width: `${leadingPct}%` }}
                        />
                      </div>
                    </div>
                  )}

                  <div className="flex items-end justify-between pt-4 border-t border-ink-line/40">
                    <span className="text-[11px] text-ink-mute font-medium">{poll.author_name}</span>
                    <div className="text-end">
                      <div className="text-2xl font-display font-black tabular text-ink leading-none">
                        {fmtInt(poll.total_votes)}
                      </div>
                      <div className="text-[10px] uppercase tracking-[0.14em] text-ink-mute mt-0.5">
                        صوت
                      </div>
                    </div>
                  </div>

                  <div className="absolute top-7 inset-inline-end-7 opacity-0 group-hover:opacity-100 transition">
                    <ArrowLeft size={14} className="text-brand-600" />
                  </div>
                </Link>
              );
            })}
          </div>
        )}

        {bootstrap.data && bootstrap.data.polls.length === 0 && (
          <div className="bg-canvas-card rounded-card p-16 text-center text-ink-mute dotgrid">
            <p className="text-sm mb-4">لا توجد استطلاعات بعد.</p>
            {canCreate && (
              <button
                onClick={() => setShowCreate(true)}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-chip bg-brand-600 text-canvas-card text-[13px] font-bold shadow-card hover:bg-brand-700 transition"
              >
                <Plus size={15} />
                ابدأ بأول استطلاع
              </button>
            )}
          </div>
        )}
      </main>

      {token && (
        <Modal
          open={showCreate}
          onClose={() => setShowCreate(false)}
          title="استطلاع جديد"
          subtitle="عرّف السؤال والخيارات وستُنشره في تطبيق iOS فوراً."
          width="lg"
        >
          <CreatePollModal
            token={token}
            onClose={() => setShowCreate(false)}
            onCreated={handleCreated}
          />
        </Modal>
      )}
    </>
  );
}
