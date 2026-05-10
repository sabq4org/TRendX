"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { Header } from "@/components/Header";
import { fmtInt } from "@/lib/format";
import { LogOut, Webhook, ChevronLeft } from "lucide-react";

const TIER_LABEL = {
  enterprise: "Enterprise",
  premium: "Premium",
  free: "Free",
} as const;

const ROLE_LABEL = {
  admin: "مشرف",
  publisher: "ناشر",
  respondent: "مستخدم",
} as const;

export default function AccountPage() {
  const { user, signOut } = useAuth();
  if (!user) return null;

  return (
    <>
      <Header eyebrow="ACCOUNT" title="الحساب" subtitle="معلومات الناشر والاشتراك." />
      <main className="flex-1 px-10 pb-10 space-y-6 max-w-3xl">
        <div className="bg-canvas-card rounded-card shadow-card p-8 flex items-center gap-6">
          <div className="w-20 h-20 rounded-card bg-brand-600 text-canvas-card grid place-items-center text-3xl font-display font-black shadow-card-lift">
            {user.avatar_initial}
          </div>
          <div className="flex-1">
            <h2 className="text-2xl font-display font-black text-ink tracking-tight leading-tight">
              {user.name}
            </h2>
            <p className="text-sm text-ink-mute mt-1">{user.email}</p>
            <div className="flex items-center gap-2 mt-3">
              <span className="text-[10px] font-bold uppercase tracking-[0.14em] px-2.5 py-1 rounded-pill bg-brand-50 text-brand-600">
                {TIER_LABEL[user.tier as keyof typeof TIER_LABEL] ?? "Free"}
              </span>
              <span className="text-[10px] font-bold uppercase tracking-[0.14em] px-2.5 py-1 rounded-pill bg-canvas-well text-ink-soft">
                {ROLE_LABEL[user.role as keyof typeof ROLE_LABEL] ?? "مستخدم"}
              </span>
            </div>
          </div>
          <button
            onClick={signOut}
            className="px-5 py-3 rounded-chip border border-ink-line/60 text-ink-soft hover:bg-negative-soft hover:text-negative hover:border-negative/30 transition flex items-center gap-2 text-sm font-bold"
          >
            <LogOut size={14} />
            تسجيل الخروج
          </button>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-3 gap-6">
          <Stat label="نقاط TRENDX" value={fmtInt(user.points)} tone="brand" />
          <Stat label="عملات TRENDX" value={user.coins.toFixed(2)} tone="accent" />
          <Stat label="المدينة" value={user.city ?? "—"} />
          <Stat label="المنطقة" value={user.region ?? "—"} />
          <Stat label="الجنس" value={user.gender === "male" ? "ذكر" : user.gender === "female" ? "أنثى" : "—"} />
          <Stat label="سنة الميلاد" value={user.birth_year ? String(user.birth_year) : "—"} />
        </div>

        <Link
          href="/account/webhooks"
          className="group bg-canvas-card rounded-card shadow-card p-6 hover:shadow-card-lift transition-all flex items-center gap-5"
        >
          <div className="w-12 h-12 rounded-chip bg-ai-50 grid place-items-center">
            <Webhook size={20} className="text-ai-700" />
          </div>
          <div className="flex-1">
            <div className="text-eyebrow text-brand-600 mb-1">DEVELOPER TOOLS</div>
            <h3 className="text-lg font-display font-bold text-ink tracking-tight">Webhooks</h3>
            <p className="text-[12px] text-ink-mute font-light mt-1">
              تنبيهات HTTPS موقّعة لكل صوت ولكل إكمال — لربط TRENDX بأنظمتك.
            </p>
          </div>
          <ChevronLeft className="text-ink-ghost group-hover:text-brand-600 group-hover:-translate-x-1 transition-transform" size={18} />
        </Link>

        <div className="bg-canvas-well rounded-card p-6 border border-ink-line/40">
          <div className="text-eyebrow text-brand-600 mb-2">API ENDPOINT</div>
          <code className="text-[12px] text-ink-soft font-mono break-all" dir="ltr">
            {process.env.NEXT_PUBLIC_TRENDX_API ?? "https://trendx-production.up.railway.app"}
          </code>
        </div>
      </main>
    </>
  );
}

function Stat({ label, value, tone }: { label: string; value: string; tone?: "brand" | "accent" }) {
  const accent =
    tone === "brand" ? "text-brand-600" :
    tone === "accent" ? "text-accent-700" :
    "text-ink";
  return (
    <div className="bg-canvas-card rounded-card shadow-card p-5">
      <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute mb-1.5">{label}</div>
      <div className={`text-2xl font-display font-black tabular ${accent} leading-none`}>{value}</div>
    </div>
  );
}
