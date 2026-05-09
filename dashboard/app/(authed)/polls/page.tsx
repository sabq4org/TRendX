"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt, fmtRelativeNow } from "@/lib/format";

export default function PollsListPage() {
  const { token } = useAuth();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);

  return (
    <>
      <Header
        title="الاستطلاعات"
        subtitle="جميع الاستطلاعات النشطة في المنصّة. اختر استطلاعاً لتحليله."
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
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {bootstrap.data.polls.map((poll) => {
              const leading = [...poll.options].sort((a, b) => b.votes_count - a.votes_count)[0];
              const leadingPct = poll.total_votes > 0 && leading
                ? Math.round((leading.votes_count / poll.total_votes) * 100)
                : 0;
              return (
                <Link
                  key={poll.id}
                  href={`/polls/${poll.id}`}
                  className="bg-canvas-card rounded-card shadow-card hover:shadow-card-hover transition p-5 group"
                >
                  <div className="flex items-center gap-2 mb-3">
                    {poll.is_featured && (
                      <span className="px-2 py-0.5 rounded-full bg-amber-50 border border-amber-200 text-amber-700 text-[10px] font-bold">
                        مميّز
                      </span>
                    )}
                    {poll.is_breaking && (
                      <span className="px-2 py-0.5 rounded-full bg-rose-50 border border-rose-200 text-rose-700 text-[10px] font-bold">
                        عاجل
                      </span>
                    )}
                    <span className="ms-auto text-[10px] text-ink-mute">{fmtRelativeNow(poll.created_at)}</span>
                  </div>

                  <h3 className="text-base font-bold text-ink leading-snug mb-2 line-clamp-2 group-hover:text-brand-600 transition">
                    {poll.title}
                  </h3>

                  {poll.topic_name && (
                    <span className="inline-block px-2 py-0.5 rounded-chip bg-canvas-well text-[10px] font-semibold text-ink-soft mb-3">
                      {poll.topic_name}
                    </span>
                  )}

                  {leading && (
                    <div className="space-y-1 mb-3">
                      <div className="flex items-center justify-between text-[11px]">
                        <span className="font-medium text-ink-soft truncate">{leading.text}</span>
                        <span className="font-bold tabular text-ink">{leadingPct}%</span>
                      </div>
                      <div className="h-1.5 rounded-full bg-canvas-well overflow-hidden">
                        <div
                          className="h-full bg-brand-500 transition-all"
                          style={{ width: `${leadingPct}%` }}
                        />
                      </div>
                    </div>
                  )}

                  <div className="flex items-center justify-between pt-3 border-t border-ink-line">
                    <span className="text-[11px] text-ink-mute">{poll.author_name}</span>
                    <span className="text-sm font-bold tabular text-ink">
                      {fmtInt(poll.total_votes)}
                      <span className="text-[10px] text-ink-mute font-medium me-1"> صوت</span>
                    </span>
                  </div>
                </Link>
              );
            })}
          </div>
        )}

        {bootstrap.data && bootstrap.data.polls.length === 0 && (
          <div className="bg-canvas-card rounded-card p-12 text-center text-ink-mute">
            لا توجد استطلاعات بعد. سيظهر العرض التجريبي هنا فور تفعيل SEED_DEMO=1 في Railway.
          </div>
        )}
      </main>
    </>
  );
}
