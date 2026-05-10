"use client";

import { useAuth } from "@/lib/auth";
import { Header } from "@/components/Header";
import { fmtInt } from "@/lib/format";
import { LogOut } from "lucide-react";

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
          <div className="w-20 h-20 rounded-card bg-sage-700 text-canvas-card grid place-items-center text-3xl font-display font-black shadow-card-lift">
            {user.avatar_initial}
          </div>
          <div className="flex-1">
            <h2 className="text-2xl font-display font-black text-ink tracking-tight leading-tight">
              {user.name}
            </h2>
            <p className="text-sm text-ink-mute mt-1">{user.email}</p>
            <div className="flex items-center gap-2 mt-3">
              <span className="text-[10px] font-bold uppercase tracking-[0.14em] px-2.5 py-1 rounded-pill bg-sage-50 text-sage-700">
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
          <Stat label="نقاط TRENDX" value={fmtInt(user.points)} tone="sage" />
          <Stat label="عملات TRENDX" value={user.coins.toFixed(2)} tone="gold" />
          <Stat label="المدينة" value={user.city ?? "—"} />
          <Stat label="المنطقة" value={user.region ?? "—"} />
          <Stat label="الجنس" value={user.gender === "male" ? "ذكر" : user.gender === "female" ? "أنثى" : "—"} />
          <Stat label="سنة الميلاد" value={user.birth_year ? String(user.birth_year) : "—"} />
        </div>

        <div className="bg-canvas-well rounded-card p-6 border border-ink-line/40">
          <div className="text-eyebrow text-sage-700 mb-2">API ENDPOINT</div>
          <code className="text-[12px] text-ink-soft font-mono break-all" dir="ltr">
            {process.env.NEXT_PUBLIC_TRENDX_API ?? "https://trendx-production.up.railway.app"}
          </code>
        </div>
      </main>
    </>
  );
}

function Stat({ label, value, tone }: { label: string; value: string; tone?: "sage" | "gold" }) {
  const accent =
    tone === "sage" ? "text-sage-700" :
    tone === "gold" ? "text-gold-700" :
    "text-ink";
  return (
    <div className="bg-canvas-card rounded-card shadow-card p-5">
      <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute mb-1.5">{label}</div>
      <div className={`text-2xl font-display font-black tabular ${accent} leading-none`}>{value}</div>
    </div>
  );
}
