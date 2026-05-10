"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { KPICard } from "@/components/KPICard";
import { LiveTicker } from "@/components/LiveTicker";
import { fmtInt, fmtPctRaw, fmtRelativeNow } from "@/lib/format";
import { ArrowLeft, Sparkles, Activity, Flame } from "lucide-react";

export default function OverviewPage() {
  const { token, user } = useAuth();
  const bootstrap = useFetch((t) => api.bootstrap(t), token);
  // Read-only pulse summary; voting happens only inside the iOS app.
  const pulse = useFetch((t) => api.pulseTodayAnon(t), token);
  const isRespondent = user?.role === "respondent";
  const streak = useFetch((t) => api.myStreak(t), token);

  if (bootstrap.loading) {
    return (
      <>
        <Header eyebrow="OVERVIEW" title="النظرة العامة" subtitle="بانتظار البيانات…" />
        <main className="flex-1 px-10 pb-10">
          <div className="grid grid-cols-4 gap-6 mb-8">
            {[0, 1, 2, 3].map((i) => (
              <div key={i} className="h-44 rounded-card shimmer" />
            ))}
          </div>
        </main>
      </>
    );
  }
  if (bootstrap.error) {
    return (
      <>
        <Header eyebrow="OVERVIEW" title="النظرة العامة" />
        <main className="px-10 pb-10">
          <div className="bg-canvas-card rounded-card p-8 text-center text-negative">
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
  const avgEngagementPct = data.polls.length > 0
    ? Math.round(totalVotesAcrossAll / data.polls.length)
    : 0;

  const topPoll = [...data.polls].sort((a, b) => b.total_votes - a.total_votes)[0];
  const topPollLeading = topPoll
    ? [...topPoll.options].sort((a, b) => b.votes_count - a.votes_count)[0]
    : null;

  return (
    <>
      <Header
        eyebrow="OVERVIEW"
        title={`أهلاً ${user?.name?.split(" ")[0] ?? ""}.`}
        subtitle={`اليوم لديك ${fmtInt(data.polls.length)} استطلاعاً نشطاً عبر ${fmtInt(data.topics.length)} قطاعات، تجمع ${fmtInt(totalVotesAcrossAll)} صوتاً تتدفّق لحظياً.`}
      />

      <main className="flex-1 px-10 pb-10 space-y-8">
        {/* Daily Pulse spotlight */}
        {pulse.data && (
          <Link
            href="/pulse"
            className="block bg-canvas-card rounded-card shadow-card-lift overflow-hidden hover:shadow-card-deep transition-shadow group"
          >
            <div className="bg-hero p-7 lg:p-8 flex items-center gap-7 relative">
              <div className="w-14 h-14 rounded-chip bg-brand-500 grid place-items-center text-canvas-card shrink-0 shadow-glow">
                <Activity size={26} strokeWidth={2.4} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-3 mb-1.5">
                  <span className="text-eyebrow text-brand-600">نبض اليوم</span>
                  {isRespondent && streak.data && streak.data.current_streak > 0 && (
                    <span className="inline-flex items-center gap-1 text-[10px] font-bold text-accent-700 bg-accent-50 px-2 py-0.5 rounded-pill">
                      <Flame size={10} /> سلسلة {streak.data.current_streak}
                    </span>
                  )}
                  <span className="text-[10px] font-bold text-ai-700 bg-ai-50/60 px-2 py-0.5 rounded-pill">
                    عرض فقط
                  </span>
                </div>
                <h2 className="text-xl lg:text-2xl font-display font-bold text-ink leading-snug">
                  {pulse.data.question}
                </h2>
                <div className="flex items-center gap-3 text-[12px] text-ink-mute mt-2">
                  <span className="tabular font-bold text-ink">{fmtInt(pulse.data.total_responses)} مشارك</span>
                  <span>•</span>
                  <span>{pulse.data.options.length} خيارات</span>
                  <span>•</span>
                  <span>التصويت من تطبيق iOS</span>
                </div>
              </div>
              <ArrowLeft size={20} className="text-brand-600 group-hover:-translate-x-1 transition-transform shrink-0" />
            </div>
          </Link>
        )}

        {/* KPI Strip */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 stagger">
          <KPICard
            index={0}
            tone="brand"
            label="استطلاعاتك النشطة"
            value={fmtInt(myPolls.length)}
            hint={`${fmtInt(myVotes)} صوتاً جمعتها حتى الآن`}
          />
          <KPICard
            index={1}
            tone="accent"
            label="استبياناتك"
            value={fmtInt(mySurveys.length)}
            hint={`${fmtInt(mySurveys.reduce((a, s) => a + s.total_responses, 0))} مستجيب`}
          />
          <KPICard
            index={2}
            tone="ai"
            label="إجمالي أصوات المنصّة"
            value={fmtInt(totalVotesAcrossAll)}
            hint={`عبر ${fmtInt(data.polls.length)} استطلاعاً`}
          />
          <KPICard
            index={3}
            tone="brand"
            label="متوسّط التفاعل"
            value={fmtInt(avgEngagementPct)}
            hint="صوت لكل استطلاع"
          />
        </div>

        {/* Spotlight + Live ticker */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 stagger">
          {/* Top poll spotlight (2/3 width) */}
          <div className="lg:col-span-2 bg-canvas-card rounded-card shadow-card overflow-hidden">
            <div className="bg-hero p-8 lg:p-10 border-b border-ink-line/40">
              <div className="flex items-center gap-2 mb-3">
                <Sparkles size={13} className="text-brand-500" />
                <span className="text-eyebrow text-brand-600">SPOTLIGHT</span>
              </div>

              {topPoll ? (
                <>
                  <h2 className="text-2xl lg:text-3xl font-display font-black text-ink leading-tight tracking-tight">
                    {topPoll.title}
                  </h2>
                  <div className="flex items-center gap-3 text-[12px] text-ink-mute mt-3">
                    <span className="font-bold">{topPoll.author_name}</span>
                    <span>•</span>
                    <span>{topPoll.topic_name ?? "بدون قطاع"}</span>
                    <span>•</span>
                    <span className="tabular font-bold text-ink">{fmtInt(topPoll.total_votes)} صوت</span>
                  </div>
                </>
              ) : (
                <p className="text-sm text-ink-mute">لا توجد استطلاعات بعد.</p>
              )}
            </div>

            {topPoll && (
              <div className="p-8 lg:p-10 space-y-4">
                {topPoll.options.map((opt) => {
                  const isLeader = opt.id === topPollLeading?.id;
                  const sharePct = topPoll.total_votes > 0
                    ? (opt.votes_count / topPoll.total_votes) * 100
                    : 0;
                  return (
                    <div key={opt.id}>
                      <div className="flex items-baseline justify-between mb-2 gap-3">
                        <span className={`text-sm leading-snug ${isLeader ? "font-bold text-ink" : "font-medium text-ink-soft"}`}>
                          {opt.text}
                        </span>
                        <div className="flex items-baseline gap-2 shrink-0">
                          <span className={`font-display font-black tabular tracking-tight ${isLeader ? "text-2xl text-brand-600" : "text-lg text-ink"}`}>
                            {sharePct.toFixed(1)}<span className="text-[12px] font-medium text-ink-mute">%</span>
                          </span>
                          <span className="text-[11px] tabular text-ink-mute">{fmtInt(opt.votes_count)}</span>
                        </div>
                      </div>
                      <div className="h-2 rounded-pill bg-canvas-well overflow-hidden">
                        <div
                          className={`h-full rounded-pill transition-all duration-700 ease-soft ${isLeader ? "bg-brand-600" : "bg-brand-300"}`}
                          style={{ width: `${sharePct}%` }}
                        />
                      </div>
                    </div>
                  );
                })}

                {topPoll.ai_insight && (
                  <div className="mt-6 p-5 rounded-chip bg-accent-50/60 border border-accent-100">
                    <div className="text-eyebrow text-accent-700 mb-2 flex items-center gap-1.5">
                      <Sparkles size={11} />
                      رؤية TRENDX AI
                    </div>
                    <p className="text-[13px] leading-relaxed text-ink-soft">{topPoll.ai_insight}</p>
                  </div>
                )}

                <Link
                  href={`/polls/${topPoll.id}`}
                  className="inline-flex items-center gap-2 text-[12px] font-bold text-brand-600 hover:gap-3 transition-all mt-2"
                >
                  افتح التحليل الكامل
                  <ArrowLeft size={13} />
                </Link>
              </div>
            )}
          </div>

          {/* Live ticker (1/3 width) */}
          <div>
            <LiveTicker />
          </div>
        </div>

        {/* Activity table — editorial style */}
        <div className="bg-canvas-card rounded-card shadow-card overflow-hidden">
          <div className="px-8 lg:px-10 py-7 border-b border-ink-line/40 flex items-baseline justify-between">
            <div>
              <div className="text-eyebrow text-brand-600 mb-1.5">RECENT ACTIVITY</div>
              <h3 className="text-xl font-display font-black text-ink tracking-tight">
                الأكثر تفاعلاً عبر المنصّة
              </h3>
            </div>
            <span className="text-[11px] tabular text-ink-mute">
              {fmtInt(data.polls.length)} استطلاعاً مُتتبَّعاً
            </span>
          </div>

          <div>
            {data.polls
              .slice()
              .sort((a, b) => b.total_votes - a.total_votes)
              .slice(0, 8)
              .map((poll, idx) => (
                <Link
                  key={poll.id}
                  href={`/polls/${poll.id}`}
                  className="flex items-center gap-5 px-8 lg:px-10 py-5 hover:bg-canvas-well/50 transition group border-b border-ink-line/30 last:border-0"
                >
                  <span className="text-[11px] font-mono font-bold tabular text-ink-mute w-8">
                    {String(idx + 1).padStart(2, "0")}
                  </span>

                  <div className="w-11 h-11 rounded-chip bg-brand-50 text-brand-600 grid place-items-center font-display font-bold text-base shrink-0">
                    {poll.author_avatar}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="text-[14px] font-medium text-ink truncate group-hover:text-brand-600 transition">
                      {poll.title}
                    </div>
                    <div className="flex items-center gap-2 text-[11px] text-ink-mute mt-1">
                      <span>{poll.author_name}</span>
                      <span>•</span>
                      <span>{fmtRelativeNow(poll.created_at)}</span>
                      {poll.topic_name && (
                        <>
                          <span>•</span>
                          <span className="font-bold text-brand-600">{poll.topic_name}</span>
                        </>
                      )}
                    </div>
                  </div>

                  <div className="text-end shrink-0">
                    <div className="text-2xl font-display font-black tabular text-ink leading-none">
                      {fmtInt(poll.total_votes)}
                    </div>
                    <div className="text-[10px] uppercase tracking-[0.14em] text-ink-mute mt-1">
                      صوت
                    </div>
                  </div>
                </Link>
              ))}
          </div>
        </div>
      </main>
    </>
  );
}
