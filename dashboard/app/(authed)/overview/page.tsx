"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { KPICard } from "@/components/KPICard";
import { LiveTicker } from "@/components/LiveTicker";
import { fmtInt, fmtPctRaw, fmtRelativeNow } from "@/lib/format";
import { TrendingUp, Sparkles, ChevronLeft } from "lucide-react";

export default function OverviewPage() {
  const { token, user } = useAuth();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);

  if (bootstrap.loading) {
    return (
      <>
        <Header title="النظرة العامة" subtitle="بانتظار البيانات…" />
        <main className="flex-1 px-9 py-6">
          <div className="grid grid-cols-4 gap-5 mb-6">
            {[0, 1, 2, 3].map((i) => (
              <div key={i} className="h-32 rounded-card shimmer" />
            ))}
          </div>
        </main>
      </>
    );
  }
  if (bootstrap.error) {
    return (
      <>
        <Header title="النظرة العامة" />
        <main className="px-9 py-8">
          <div className="bg-canvas-card rounded-card p-6 text-center text-danger">
            تعذّر جلب البيانات: {bootstrap.error}
          </div>
        </main>
      </>
    );
  }

  const data = bootstrap.data!;
  const myPolls = data.polls.filter((p) => p.publisher_id === user?.id);
  const mySurveys = data.surveys.filter((s) => s.publisher_id === user?.id);
  const myVotes = myPolls.reduce((acc, p) => acc + p.total_votes, 0);
  const totalVotesAcrossAll = data.polls.reduce((acc, p) => acc + p.total_votes, 0);
  const totalSurveyResponses = data.surveys.reduce((acc, s) => acc + s.total_responses, 0);
  const avgConversion = data.polls.length > 0
    ? Math.round((data.polls.reduce((acc, p) => acc + p.total_votes, 0) / Math.max(1, data.polls.length)) / 50 * 100)
    : 0;

  // Find most engaging poll (max votes)
  const topPoll = [...data.polls].sort((a, b) => b.total_votes - a.total_votes)[0];

  return (
    <>
      <Header
        title="النظرة العامة"
        subtitle={`أهلاً ${user?.name ?? ""} — ${data.polls.length} استطلاعاً نشطاً، ${fmtInt(totalVotesAcrossAll)} صوتاً مسجّلاً عبر القطاعات.`}
      />

      <main className="flex-1 px-9 py-6 space-y-6">
        {/* KPI strip */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
          <KPICard
            label="استطلاعاتك النشطة"
            value={fmtInt(myPolls.length)}
            hint={`${fmtInt(myVotes)} صوتاً جمعتها`}
          />
          <KPICard
            label="استبياناتك"
            value={fmtInt(mySurveys.length)}
            hint={`${fmtInt(mySurveys.reduce((a, s) => a + s.total_responses, 0))} مستجيب`}
            accent="brand"
          />
          <KPICard
            label="إجمالي الأصوات (المنصّة)"
            value={fmtInt(totalVotesAcrossAll)}
            hint={`من ${fmtInt(data.polls.length)} استطلاع`}
          />
          <KPICard
            label="متوسط التحويل"
            value={fmtPctRaw(avgConversion, 0)}
            hint="مُعدّل التصويت لكل استطلاع"
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
          {/* Live ticker */}
          <div className="lg:col-span-1">
            <LiveTicker />
          </div>

          {/* Top poll spotlight */}
          <div className="lg:col-span-2 bg-canvas-card rounded-card shadow-card p-6">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-ink flex items-center gap-2">
                <Sparkles size={15} className="text-brand-500" />
                الاستطلاع الأكثر تفاعلاً الآن
              </h3>
              {topPoll && (
                <Link
                  href={`/polls/${topPoll.id}`}
                  className="text-[11px] font-bold text-brand-600 flex items-center gap-1 hover:gap-2 transition-all"
                >
                  افتح التحليل الكامل
                  <ChevronLeft size={13} />
                </Link>
              )}
            </div>

            {topPoll ? (
              <>
                <h2 className="text-lg font-bold text-ink leading-snug mb-1">{topPoll.title}</h2>
                <div className="flex items-center gap-3 text-[11px] text-ink-mute mb-5">
                  <span>{topPoll.author_name}</span>
                  <span>·</span>
                  <span>{topPoll.topic_name ?? "بدون قطاع"}</span>
                  <span>·</span>
                  <span className="tabular">{fmtInt(topPoll.total_votes)} صوت</span>
                </div>
                <ul className="space-y-2.5">
                  {topPoll.options.map((opt) => {
                    const max = Math.max(1, ...topPoll.options.map((o) => o.votes_count));
                    const widthPct = (opt.votes_count / max) * 100;
                    const sharePct = topPoll.total_votes > 0
                      ? (opt.votes_count / topPoll.total_votes) * 100
                      : 0;
                    return (
                      <li key={opt.id}>
                        <div className="flex items-center justify-between text-xs mb-1.5">
                          <span className="font-medium text-ink-soft">{opt.text}</span>
                          <span className="font-bold tabular text-ink">
                            {fmtInt(opt.votes_count)}
                            <span className="text-ink-mute font-medium me-1">
                              {" "}· {fmtPctRaw(sharePct, 1)}
                            </span>
                          </span>
                        </div>
                        <div className="h-2 rounded-full bg-canvas-well overflow-hidden">
                          <div
                            className="h-full bg-brand-500 transition-all"
                            style={{ width: `${widthPct}%` }}
                          />
                        </div>
                      </li>
                    );
                  })}
                </ul>
                {topPoll.ai_insight && (
                  <div className="mt-5 p-3.5 rounded-chip bg-brand-50/60 border border-brand-100 text-[13px] leading-relaxed text-ink-soft">
                    <span className="font-bold text-brand-700 me-1">رؤية TRENDX AI:</span>
                    {topPoll.ai_insight}
                  </div>
                )}
              </>
            ) : (
              <div className="text-sm text-ink-mute py-8 text-center">
                لا توجد استطلاعات بعد — أنشئ أولها من تطبيق iOS.
              </div>
            )}
          </div>
        </div>

        {/* Recent activity feed: list of polls with totals */}
        <div className="bg-canvas-card rounded-card shadow-card p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-bold text-ink flex items-center gap-2">
              <TrendingUp size={15} className="text-ink-mute" />
              نشاط حديث عبر المنصّة
            </h3>
            <span className="text-[11px] text-ink-mute">{fmtInt(data.polls.length)} استطلاعاً</span>
          </div>

          <ul className="divide-y divide-ink-line">
            {data.polls
              .slice()
              .sort((a, b) => b.total_votes - a.total_votes)
              .slice(0, 8)
              .map((poll) => (
                <li key={poll.id}>
                  <Link
                    href={`/polls/${poll.id}`}
                    className="flex items-center gap-4 py-3 hover:bg-canvas-well/50 -mx-2 px-2 rounded-chip transition"
                  >
                    <div className="w-9 h-9 rounded-chip bg-brand-50 text-brand-700 grid place-items-center font-bold text-sm">
                      {poll.author_avatar}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-sm font-medium text-ink truncate">{poll.title}</div>
                      <div className="flex items-center gap-2 text-[11px] text-ink-mute mt-0.5">
                        <span>{poll.author_name}</span>
                        <span>·</span>
                        <span>{fmtRelativeNow(poll.created_at)}</span>
                        {poll.topic_name && (
                          <>
                            <span>·</span>
                            <span>{poll.topic_name}</span>
                          </>
                        )}
                      </div>
                    </div>
                    <div className="text-end">
                      <div className="text-sm font-bold tabular text-ink">{fmtInt(poll.total_votes)}</div>
                      <div className="text-[10px] text-ink-mute">صوت</div>
                    </div>
                  </Link>
                </li>
              ))}
          </ul>
        </div>
      </main>
    </>
  );
}
