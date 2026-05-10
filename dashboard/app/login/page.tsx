"use client";

import { useState } from "react";
import { useAuth } from "@/lib/auth";

export default function LoginPage() {
  const { signIn, loading } = useAuth();
  const [email, setEmail] = useState("official@trendx.app");
  const [password, setPassword] = useState("trendx-demo-2026");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await signIn(email, password);
    } catch (err) {
      setError(err instanceof Error ? err.message : "حدث خطأ غير متوقّع");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="min-h-screen flex">
      {/* Left brand canvas */}
      <div className="hidden lg:flex flex-1 relative overflow-hidden bg-hero">
        <div className="absolute inset-0 dotgrid opacity-50" />
        <div className="relative z-10 flex flex-col justify-between p-14 w-full">
          <div>
            <div className="flex items-baseline gap-2.5 mb-1">
              <span className="text-5xl font-display font-black tracking-tight text-ink">TRENDX</span>
              <span className="w-2 h-2 rounded-full bg-sage-500" />
            </div>
            <p className="text-sm font-bold uppercase tracking-[0.22em] text-sage-700">
              ذكاء الرأي السعودي
            </p>
          </div>

          <div>
            <blockquote className="text-3xl font-display font-light text-ink leading-snug max-w-xl">
              «من البيانات الخام إلى قرارات تصنع الفارق —
              <span className="font-black text-sage-700"> هنا يبدأ الذكاء الإستراتيجي.</span>»
            </blockquote>

            <div className="flex items-center gap-8 mt-12 pt-8 border-t border-ink-line/60">
              <div>
                <div className="text-3xl font-display font-black tabular text-ink">507+</div>
                <div className="text-[11px] uppercase tracking-[0.18em] text-ink-mute mt-1">صوت محلّل</div>
              </div>
              <div>
                <div className="text-3xl font-display font-black tabular text-ink">13</div>
                <div className="text-[11px] uppercase tracking-[0.18em] text-ink-mute mt-1">استطلاع نشط</div>
              </div>
              <div>
                <div className="text-3xl font-display font-black tabular text-ink">6</div>
                <div className="text-[11px] uppercase tracking-[0.18em] text-ink-mute mt-1">قطاع</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Right form */}
      <div className="flex-1 flex items-center justify-center p-8 lg:p-14 bg-canvas-card">
        <div className="w-full max-w-sm">
          <div className="lg:hidden mb-10 text-center">
            <div className="flex items-baseline justify-center gap-2 mb-1">
              <span className="text-3xl font-display font-black text-ink">TRENDX</span>
              <span className="w-1.5 h-1.5 rounded-full bg-sage-500" />
            </div>
          </div>

          <div className="mb-9">
            <div className="text-eyebrow text-sage-700 mb-3">SIGN IN</div>
            <h1 className="text-3xl font-display font-black text-ink leading-tight">
              مرحباً بعودتك
            </h1>
            <p className="text-sm text-ink-mute mt-2 font-light">
              ادخل لمتابعة لوحتك ومؤشّراتك.
            </p>
          </div>

          <form onSubmit={onSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-[11px] font-bold uppercase tracking-[0.14em] text-ink-soft">
                البريد الإلكتروني
              </label>
              <input
                type="email"
                required
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3.5 rounded-chip border border-ink-line bg-canvas-well/40 focus:bg-canvas-card focus:border-sage-500 focus:outline-none focus:ring-4 focus:ring-sage-500/15 text-sm transition"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-[11px] font-bold uppercase tracking-[0.14em] text-ink-soft">
                كلمة المرور
              </label>
              <input
                type="password"
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3.5 rounded-chip border border-ink-line bg-canvas-well/40 focus:bg-canvas-card focus:border-sage-500 focus:outline-none focus:ring-4 focus:ring-sage-500/15 text-sm transition"
              />
            </div>

            {error && (
              <div className="text-[12px] text-negative bg-negative-soft border border-negative/20 px-3.5 py-2.5 rounded-chip">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={submitting || loading}
              className="w-full bg-sage-700 hover:bg-sage-900 disabled:bg-sage-300 disabled:cursor-not-allowed text-canvas-card font-bold py-3.5 rounded-chip text-sm transition shadow-card hover:shadow-card-lift"
            >
              {submitting ? "جارٍ الدخول..." : "تسجيل الدخول"}
            </button>

            <div className="text-[11px] text-ink-mute text-center pt-3 leading-relaxed">
              استخدم حساب الناشر التجريبي،
              <br />
              أو حساب iOS الخاص بك.
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
