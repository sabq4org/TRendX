"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowLeft, Plus, Trash2, Send, Eye, EyeOff } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { Header } from "@/components/Header";
import type { Webhook } from "@/lib/types";
import { fmtRelativeNow } from "@/lib/format";
import clsx from "clsx";

const EVENT_OPTIONS = [
  { value: "poll.published",        label: "نشر استطلاع" },
  { value: "poll.vote_cast",        label: "صوت جديد" },
  { value: "poll.vote_milestone",   label: "حدّ تصويت (× 100)" },
  { value: "poll.ended",            label: "انتهاء استطلاع" },
  { value: "survey.published",      label: "نشر استبيان" },
  { value: "survey.response",       label: "إجابة استبيان" },
  { value: "survey.completed",      label: "إكمال استبيان" },
  { value: "ai.report_ready",       label: "جاهزيّة تقرير AI" },
];

export default function PublisherWebhooksPage() {
  const { token } = useAuth();
  const [webhooks, setWebhooks] = useState<Webhook[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // create form state
  const [url, setUrl] = useState("");
  const [events, setEvents] = useState<string[]>(["poll.vote_milestone"]);
  const [creating, setCreating] = useState(false);
  const [createMessage, setCreateMessage] = useState<string | null>(null);

  // per-row state
  const [revealedSecret, setRevealedSecret] = useState<string | null>(null);
  const [testing, setTesting] = useState<string | null>(null);
  const [testResult, setTestResult] = useState<Record<string, { ok: boolean; status: number; response: string }>>({});

  async function load() {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      const list = await api.listWebhooks(token);
      setWebhooks(list);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  async function create() {
    if (!token) return;
    if (!url.startsWith("https://")) {
      setCreateMessage("يجب أن يبدأ العنوان بـ https://");
      return;
    }
    if (events.length === 0) {
      setCreateMessage("اختر حدثاً واحداً على الأقل.");
      return;
    }
    setCreating(true);
    setCreateMessage(null);
    try {
      await api.createWebhook(token, { url, events });
      setUrl("");
      setEvents(["poll.vote_milestone"]);
      await load();
    } catch (err) {
      setCreateMessage(err instanceof Error ? err.message : String(err));
    } finally {
      setCreating(false);
    }
  }

  async function remove(id: string) {
    if (!token) return;
    if (!confirm("حذف هذا Webhook؟")) return;
    await api.deleteWebhook(token, id);
    await load();
  }

  async function toggle(id: string, isActive: boolean) {
    if (!token) return;
    await api.updateWebhook(token, id, { is_active: !isActive });
    await load();
  }

  async function test(id: string) {
    if (!token) return;
    setTesting(id);
    try {
      const result = await api.testWebhook(token, id);
      setTestResult((prev) => ({ ...prev, [id]: result }));
    } finally {
      setTesting(null);
    }
  }

  return (
    <>
      <Header
        eyebrow="ACCOUNT — WEBHOOKS"
        title="Webhooks"
        subtitle="استقبل تنبيهات لحظيّة في أنظمتك الخاصّة عند كل حدث مهمّ."
        right={
          <Link
            href="/account"
            className="inline-flex items-center gap-1.5 text-[11px] font-bold text-ink-mute hover:text-brand-600 transition"
          >
            <ArrowLeft size={12} className="rotate-180" /> الحساب
          </Link>
        }
      />
      <main className="flex-1 px-10 pb-10 space-y-6">
        {/* Create form */}
        <section className="bg-canvas-card rounded-card shadow-card p-7">
          <div className="text-eyebrow text-brand-600 mb-2">CREATE</div>
          <h3 className="text-lg font-display font-bold text-ink mb-5 tracking-tight">
            إضافة Webhook جديد
          </h3>
          <div className="space-y-4">
            <label className="block">
              <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute mb-1.5">
                Endpoint URL (HTTPS)
              </div>
              <input
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="https://your-server.com/trendx/webhook"
                dir="ltr"
                className="w-full px-4 py-3 rounded-chip border border-ink-line bg-canvas-card focus:border-brand-500 focus:outline-none focus:ring-4 focus:ring-brand-500/15 text-sm transition font-mono"
              />
            </label>

            <div>
              <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute mb-2">
                الأحداث المشترك بها
              </div>
              <div className="flex flex-wrap gap-2">
                {EVENT_OPTIONS.map((ev) => {
                  const active = events.includes(ev.value);
                  return (
                    <button
                      key={ev.value}
                      onClick={() => setEvents((prev) => active
                        ? prev.filter((x) => x !== ev.value)
                        : [...prev, ev.value])}
                      className={clsx(
                        "text-[12px] font-bold px-3 py-1.5 rounded-pill transition",
                        active
                          ? "brand-fill"
                          : "bg-canvas-well text-ink-soft hover:text-ink",
                      )}
                    >
                      {ev.label}
                    </button>
                  );
                })}
              </div>
            </div>

            {createMessage && (
              <div className="text-[12px] text-negative">{createMessage}</div>
            )}

            <button
              onClick={create}
              disabled={creating || !url || events.length === 0}
              className="brand-fill disabled:opacity-50 font-bold py-2.5 px-5 rounded-chip text-sm transition shadow-card hover:shadow-glow inline-flex items-center gap-2"
            >
              <Plus size={14} /> {creating ? "جارٍ الإضافة…" : "إضافة Webhook"}
            </button>
          </div>
        </section>

        {/* List */}
        <section className="bg-canvas-card rounded-card shadow-card overflow-hidden">
          <div className="px-7 py-5 border-b border-ink-line/40">
            <div className="text-eyebrow text-brand-600 mb-1">YOUR WEBHOOKS</div>
            <h3 className="text-base font-display font-bold text-ink tracking-tight">
              قائمة الـ Webhooks
            </h3>
          </div>

          {loading ? (
            <div className="p-12 text-center">
              <div className="w-8 h-8 mx-auto rounded-full border-2 border-ink-line border-t-brand-500 animate-spin" />
            </div>
          ) : error ? (
            <div className="p-10 text-center text-negative text-sm">{error}</div>
          ) : webhooks.length === 0 ? (
            <div className="p-12 text-center text-sm text-ink-mute dotgrid">
              لم تضف أي Webhook بعد. أضف أول واحد بالأعلى.
            </div>
          ) : (
            <ul className="divide-y divide-ink-line/30">
              {webhooks.map((wh) => (
                <li key={wh.id} className="px-7 py-5">
                  <div className="flex items-start gap-5">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-3 mb-1.5">
                        <span className={
                          "text-[10px] font-bold px-2 py-0.5 rounded-pill " +
                          (wh.is_active ? "bg-positive-soft text-positive" : "bg-canvas-well text-ink-mute")
                        }>
                          {wh.is_active ? "نشط" : "موقوف"}
                        </span>
                        {wh.failure_count > 0 && (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded-pill bg-negative-soft text-negative">
                            {wh.failure_count} فشل متتالي
                          </span>
                        )}
                      </div>
                      <code className="text-[12px] font-mono text-ink truncate block" dir="ltr">
                        {wh.url}
                      </code>
                      <div className="flex flex-wrap gap-1 mt-2">
                        {wh.events.map((e) => (
                          <span key={e} className="text-[10px] font-mono text-brand-600 bg-brand-50 px-2 py-0.5 rounded-pill">
                            {e}
                          </span>
                        ))}
                      </div>
                      {wh.last_fired_at && (
                        <div className="text-[10px] text-ink-mute mt-2 font-mono">
                          آخر إطلاق: {fmtRelativeNow(wh.last_fired_at)}
                        </div>
                      )}

                      {/* Secret reveal */}
                      <div className="mt-3 flex items-center gap-2 bg-canvas-well rounded-chip p-2.5">
                        <span className="text-[10px] uppercase tracking-[0.14em] text-ink-mute font-bold">SECRET</span>
                        <code className="text-[11px] font-mono text-ink-soft flex-1 truncate" dir="ltr">
                          {revealedSecret === wh.id ? wh.secret : "•".repeat(24)}
                        </code>
                        <button
                          onClick={() => setRevealedSecret(revealedSecret === wh.id ? null : wh.id)}
                          className="text-ink-mute hover:text-brand-600"
                          title="إظهار/إخفاء"
                        >
                          {revealedSecret === wh.id ? <EyeOff size={12} /> : <Eye size={12} />}
                        </button>
                      </div>

                      {testResult[wh.id] && (
                        <div className={
                          "mt-3 text-[11px] p-2.5 rounded-chip " +
                          (testResult[wh.id].ok ? "bg-positive-soft text-positive" : "bg-negative-soft text-negative")
                        }>
                          <span className="font-bold tabular">{testResult[wh.id].status || "—"}</span>{" "}
                          {testResult[wh.id].response.slice(0, 120) || (testResult[wh.id].ok ? "OK" : "Failed")}
                        </div>
                      )}
                    </div>

                    <div className="flex flex-col gap-2 shrink-0">
                      <button
                        onClick={() => test(wh.id)}
                        disabled={testing === wh.id}
                        className="text-[11px] font-bold px-3 py-1.5 rounded-chip border border-ink-line hover:border-brand-500 hover:text-brand-600 disabled:opacity-50 inline-flex items-center gap-1.5 transition"
                      >
                        <Send size={11} />
                        {testing === wh.id ? "جارٍ…" : "اختبار"}
                      </button>
                      <button
                        onClick={() => toggle(wh.id, wh.is_active)}
                        className="text-[11px] font-bold px-3 py-1.5 rounded-chip border border-ink-line hover:border-brand-500 hover:text-brand-600 transition"
                      >
                        {wh.is_active ? "إيقاف" : "تفعيل"}
                      </button>
                      <button
                        onClick={() => remove(wh.id)}
                        className="text-[11px] font-bold px-3 py-1.5 rounded-chip border border-negative/30 text-negative hover:bg-negative/5 transition inline-flex items-center gap-1.5"
                      >
                        <Trash2 size={11} /> حذف
                      </button>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>

        {/* Docs */}
        <section className="bg-canvas-card rounded-card shadow-card p-7">
          <div className="text-eyebrow text-brand-600 mb-2">VERIFY</div>
          <h3 className="text-base font-display font-bold text-ink mb-3 tracking-tight">
            التحقّق من توقيع TRENDX
          </h3>
          <p className="text-[13px] text-ink-soft leading-relaxed font-light mb-3">
            كل طلب موقّع برأس <code className="font-mono text-brand-600">X-TRENDX-Signature: sha256=…</code>.
            التحقّق على جانبك:
          </p>
          <pre dir="ltr" className="text-[11px] font-mono bg-canvas-well rounded-chip p-3 overflow-x-auto leading-relaxed">
{`const expected = crypto
  .createHmac('sha256', WEBHOOK_SECRET)
  .update(rawBody)
  .digest('hex');
const ok = expected === request.headers['x-trendx-signature'].replace('sha256=', '');`}
          </pre>
        </section>
      </main>
    </>
  );
}
