"use client";

import { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Play, Activity } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import { fmtInt, fmtRelativeNow } from "@/lib/format";

export default function AdminJobsPage() {
  const { token, user } = useAuth();
  const status = useFetch((t) => api.adminJobsStatus(t), token);
  const [running, setRunning] = useState(false);
  const [feedback, setFeedback] = useState<string | null>(null);

  async function runSnapshots() {
    if (!token || running) return;
    setRunning(true);
    setFeedback(null);
    try {
      const result = await api.adminRunSnapshots(token);
      setFeedback(`تم تشغيل التقاط البيانات. ${new Date(result.ranAt).toLocaleTimeString("en-US")}`);
      status.refresh();
    } catch (err) {
      setFeedback(err instanceof Error ? err.message : String(err));
    } finally {
      setRunning(false);
    }
  }

  if (user && user.role !== "admin") {
    return (
      <>
        <Header eyebrow="ADMIN" title="حالة المهام" />
        <main className="px-10 pb-10">
          <div className="bg-negative-soft border border-negative/20 rounded-card p-8 text-center text-sm text-negative">
            صلاحية الإدارة مطلوبة.
          </div>
        </main>
      </>
    );
  }

  return (
    <>
      <Header
        eyebrow="ADMIN — JOBS"
        title="حالة المهام"
        subtitle="نبضات النظام: snapshots، تقارير AI، Webhook deliveries."
        right={
          <Link
            href="/admin"
            className="inline-flex items-center gap-1.5 text-[11px] font-bold text-ink-mute hover:text-brand-600 transition"
          >
            <ArrowLeft size={12} className="rotate-180" /> العودة
          </Link>
        }
      />
      <main className="flex-1 px-10 pb-10 space-y-6">
        {status.loading && !status.data ? (
          <div className="bg-canvas-card rounded-card p-16 text-center">
            <div className="w-8 h-8 mx-auto rounded-full border-2 border-ink-line border-t-brand-500 animate-spin" />
          </div>
        ) : status.error ? (
          <div className="bg-negative-soft border border-negative/20 rounded-card p-6 text-sm text-negative">
            {status.error}
          </div>
        ) : status.data ? (
          <>
            {/* KPI grid */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-5 stagger">
              <Card title="آخر Snapshot" tone="brand">
                {status.data.snapshot ? (
                  <>
                    <div className="text-2xl font-display font-black text-ink tabular tracking-tight">
                      {fmtRelativeNow(status.data.snapshot.computed_at)}
                    </div>
                    <div className="text-[11px] font-mono text-ink-mute mt-2">
                      {status.data.snapshot.entity_type}
                    </div>
                  </>
                ) : (
                  <div className="text-sm text-ink-mute">لا snapshot بعد.</div>
                )}
              </Card>

              <Card title="آخر تقرير AI" tone="accent">
                {status.data.last_ai_insight ? (
                  <>
                    <div className="text-2xl font-display font-black text-ink tabular tracking-tight">
                      {fmtRelativeNow(status.data.last_ai_insight.generated_at)}
                    </div>
                    <div className="text-[11px] text-ink-mute mt-2">
                      <span className="font-mono">{status.data.last_ai_insight.model}</span>
                      {status.data.last_ai_insight.latency_ms !== null && (
                        <> • {fmtInt(status.data.last_ai_insight.latency_ms)}ms</>
                      )}
                    </div>
                  </>
                ) : (
                  <div className="text-sm text-ink-mute">لم يتم توليد تقارير.</div>
                )}
              </Card>

              <Card title="Webhooks النشطة" tone="ai">
                <div className="text-3xl font-display font-black text-ink tabular tracking-tight leading-none">
                  {fmtInt(status.data.webhooks.active)}
                  <span className="text-base text-ink-mute ms-1.5">/ {fmtInt(status.data.webhooks.total)}</span>
                </div>
                <div className="text-[11px] text-ink-mute mt-2">نشط / المجموع</div>
              </Card>
            </div>

            {/* Run snapshots */}
            <div className="bg-canvas-card rounded-card shadow-card p-6 flex items-center justify-between">
              <div>
                <div className="text-eyebrow text-brand-600 mb-1">MANUAL TRIGGER</div>
                <h3 className="text-base font-display font-bold text-ink tracking-tight">
                  تشغيل التقاط البيانات الآن
                </h3>
                <p className="text-[12px] text-ink-mute mt-1 font-light">
                  إعادة احتساب الـ snapshot لكل الاستطلاعات والاستبيانات النشطة.
                </p>
                {feedback && <p className="text-[11px] text-positive mt-2">{feedback}</p>}
              </div>
              <button
                onClick={runSnapshots}
                disabled={running}
                className="brand-fill disabled:opacity-50 font-bold py-2.5 px-5 rounded-chip text-xs transition shadow-card hover:shadow-glow inline-flex items-center gap-2"
              >
                {running ? (
                  <>
                    <Activity size={12} className="animate-pulse" /> جارٍ التشغيل…
                  </>
                ) : (
                  <>
                    <Play size={12} /> تشغيل
                  </>
                )}
              </button>
            </div>

            {/* Recent webhook deliveries */}
            <div className="bg-canvas-card rounded-card shadow-card overflow-hidden">
              <div className="px-6 py-4 border-b border-ink-line/40">
                <div className="text-eyebrow text-brand-600 mb-1">RECENT DELIVERIES</div>
                <h3 className="text-base font-display font-bold text-ink tracking-tight">
                  آخر تسليمات Webhooks
                </h3>
              </div>
              {status.data.recent_webhook_deliveries.length === 0 ? (
                <div className="p-12 text-center text-sm text-ink-mute">لا توجد عمليات تسليم بعد.</div>
              ) : (
                <ul className="divide-y divide-ink-line/30">
                  {status.data.recent_webhook_deliveries.map((d) => {
                    const meta = (d.metadata ?? {}) as Record<string, unknown>;
                    const status_code = typeof meta.status === "number" ? meta.status : 0;
                    const event = typeof meta.event === "string" ? meta.event : "";
                    return (
                      <li key={d.id} className="px-6 py-3 flex items-center gap-4 hover:bg-canvas-well/40 transition">
                        <span className={
                          "text-[10px] font-bold px-2 py-0.5 rounded-pill tabular " +
                          (d.action === "webhook.delivered" ? "bg-positive-soft text-positive" : "bg-negative-soft text-negative")
                        }>
                          {status_code || "—"}
                        </span>
                        <span className="text-[12px] font-mono text-ink-soft">{event}</span>
                        <span className="ms-auto text-[11px] text-ink-mute font-mono">
                          {fmtRelativeNow(d.created_at)}
                        </span>
                      </li>
                    );
                  })}
                </ul>
              )}
            </div>
          </>
        ) : null}
      </main>
    </>
  );
}

function Card({
  title, tone, children,
}: {
  title: string;
  tone: "brand" | "accent" | "ai";
  children: React.ReactNode;
}) {
  const bar = tone === "brand" ? "text-brand-500" : tone === "accent" ? "text-accent-500" : "text-ai-500";
  return (
    <div className="relative bg-canvas-card rounded-card shadow-card p-5 overflow-hidden">
      <span className={`accent-bar ${bar}`} aria-hidden />
      <div className="text-eyebrow text-ink-mute mb-2">{title}</div>
      {children}
    </div>
  );
}
