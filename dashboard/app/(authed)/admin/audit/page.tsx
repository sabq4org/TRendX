"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";

const ACTION_COLOR: Record<string, string> = {
  "webhook.delivered":          "bg-positive-soft text-positive",
  "webhook.failed":             "bg-negative-soft text-negative",
  "webhook.auto_deactivated":   "bg-negative-soft text-negative",
  "user.updated":               "bg-brand-50 text-brand-600",
  "sector.created":             "bg-accent-50 text-accent-700",
  "sector.updated":             "bg-accent-50 text-accent-700",
};

export default function AdminAuditPage() {
  const { token, user } = useAuth();
  const auditLog = useFetch((t) => api.adminAuditLog(t, 200), token);

  if (user && user.role !== "admin") {
    return (
      <>
        <Header eyebrow="ADMIN" title="سجل التدقيق" />
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
        eyebrow="ADMIN — AUDIT"
        title="سجل التدقيق"
        subtitle="آخر 200 حدث إداري وتسليم Webhook، مرتّبة من الأحدث."
        right={
          <Link
            href="/admin"
            className="inline-flex items-center gap-1.5 text-[11px] font-bold text-ink-mute hover:text-brand-600 transition"
          >
            <ArrowLeft size={12} className="rotate-180" /> العودة
          </Link>
        }
      />
      <main className="flex-1 px-10 pb-10">
        <div className="bg-canvas-card rounded-card shadow-card overflow-hidden">
          {auditLog.loading ? (
            <div className="p-16 text-center">
              <div className="w-8 h-8 mx-auto rounded-full border-2 border-ink-line border-t-brand-500 animate-spin" />
            </div>
          ) : auditLog.error ? (
            <div className="p-12 text-center text-negative text-sm">{auditLog.error}</div>
          ) : !auditLog.data || auditLog.data.length === 0 ? (
            <div className="p-16 text-center text-sm text-ink-mute">لا توجد أحداث بعد.</div>
          ) : (
            <ul className="divide-y divide-ink-line/30">
              {auditLog.data.map((entry) => (
                <li key={entry.id} className="px-7 py-4 hover:bg-canvas-well/40 transition">
                  <div className="flex items-start justify-between gap-5">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-3 mb-1.5">
                        <span
                          className={
                            "text-[10px] font-bold px-2.5 py-1 rounded-pill " +
                            (ACTION_COLOR[entry.action] ?? "bg-canvas-well text-ink-soft")
                          }
                        >
                          {entry.action}
                        </span>
                        <span className="text-[11px] font-mono text-ink-mute">
                          {entry.resource_type}
                          {entry.resource_id ? ` · ${entry.resource_id.slice(0, 8)}…` : ""}
                        </span>
                      </div>
                      {entry.metadata && (
                        <pre className="text-[11px] text-ink-soft bg-canvas-well rounded-chip p-2.5 mt-2 overflow-x-auto font-mono">
                          {JSON.stringify(entry.metadata, null, 2).slice(0, 600)}
                        </pre>
                      )}
                    </div>
                    <div className="text-end shrink-0">
                      <div className="text-[11px] tabular text-ink-mute font-mono">
                        {new Date(entry.created_at).toLocaleString("en-US")}
                      </div>
                      {entry.actor_id && (
                        <div className="text-[10px] text-ink-ghost font-mono mt-0.5">
                          {entry.actor_id.slice(0, 8)}
                        </div>
                      )}
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      </main>
    </>
  );
}
