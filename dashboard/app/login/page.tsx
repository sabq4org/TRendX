"use client";

import { useState } from "react";
import { useAuth } from "@/lib/auth";
import { TrendingUp } from "lucide-react";

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
    <div className="min-h-screen flex items-center justify-center p-6 bg-canvas">
      {/* Decorative background */}
      <div className="fixed inset-0 -z-10 pointer-events-none">
        <div
          className="absolute -top-32 -right-32 w-96 h-96 rounded-full opacity-30 blur-3xl"
          style={{ background: "radial-gradient(circle, #DDE3FD 0%, transparent 70%)" }}
        />
        <div
          className="absolute -bottom-32 -left-32 w-96 h-96 rounded-full opacity-25 blur-3xl"
          style={{ background: "radial-gradient(circle, #C6D9FF 0%, transparent 70%)" }}
        />
      </div>

      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-3 mb-5">
            <div className="w-12 h-12 rounded-2xl bg-brand-500 text-white grid place-items-center shadow-card">
              <TrendingUp size={22} strokeWidth={2.5} />
            </div>
            <span className="text-3xl font-bold tracking-tight text-ink">TRENDX</span>
          </div>
          <p className="text-ink-mute text-sm font-medium">
            لوحة الناشر — حيث تُترجَم الأصوات إلى قرارات
          </p>
        </div>

        <form
          onSubmit={onSubmit}
          className="bg-canvas-card rounded-card shadow-card p-7 space-y-5"
        >
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-ink-soft">البريد الإلكتروني</label>
            <input
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3.5 py-3 rounded-chip border border-ink-line bg-canvas-well focus:border-brand-500 focus:outline-none focus:ring-4 focus:ring-brand-100 text-sm transition"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-ink-soft">كلمة المرور</label>
            <input
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3.5 py-3 rounded-chip border border-ink-line bg-canvas-well focus:border-brand-500 focus:outline-none focus:ring-4 focus:ring-brand-100 text-sm transition"
            />
          </div>

          {error && (
            <div className="text-xs text-danger bg-danger/5 border border-danger/15 px-3 py-2 rounded-chip">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={submitting || loading}
            className="w-full bg-brand-500 hover:bg-brand-600 disabled:bg-brand-300 disabled:cursor-not-allowed text-white font-semibold py-3 rounded-chip text-sm transition shadow-card"
          >
            {submitting ? "جاري الدخول..." : "تسجيل الدخول"}
          </button>

          <div className="text-[11px] text-ink-mute text-center pt-1">
            استخدم حساب الناشر التجريبي أو حساب iOS الخاص بك.
          </div>
        </form>
      </div>
    </div>
  );
}
