"use client";

import { useAuth } from "@/lib/auth";
import { Header } from "@/components/Header";
import { fmtInt } from "@/lib/format";
import { LogOut } from "lucide-react";

export default function AccountPage() {
  const { user, signOut } = useAuth();
  if (!user) return null;

  const tierLabel = user.tier === "enterprise"
    ? "Enterprise"
    : user.tier === "premium" ? "Premium" : "Free";

  return (
    <>
      <Header title="الحساب" subtitle="معلومات الناشر والاشتراك." />
      <main className="flex-1 px-9 py-6 space-y-5 max-w-3xl">
        <div className="bg-canvas-card rounded-card shadow-card p-6 flex items-center gap-5">
          <div className="w-16 h-16 rounded-2xl bg-brand-100 text-brand-700 grid place-items-center text-2xl font-bold">
            {user.avatar_initial}
          </div>
          <div className="flex-1">
            <h2 className="text-xl font-bold text-ink">{user.name}</h2>
            <p className="text-sm text-ink-mute mt-0.5">{user.email}</p>
            <div className="flex items-center gap-2 mt-2">
              <span className="text-[10px] font-bold uppercase px-2 py-0.5 rounded-full bg-brand-50 text-brand-700">
                {tierLabel}
              </span>
              <span className="text-[10px] font-bold uppercase px-2 py-0.5 rounded-full bg-canvas-well text-ink-soft">
                {user.role === "admin" ? "مشرف" : user.role === "publisher" ? "ناشر" : "مستخدم"}
              </span>
            </div>
          </div>
          <button
            onClick={signOut}
            className="px-4 py-2.5 rounded-chip border border-ink-line text-ink-soft hover:bg-danger/5 hover:text-danger hover:border-danger/30 transition flex items-center gap-2 text-sm font-semibold"
          >
            <LogOut size={14} />
            تسجيل الخروج
          </button>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-3 gap-5">
          <Stat label="نقاط TRENDX" value={fmtInt(user.points)} />
          <Stat label="عملات TRENDX" value={user.coins.toFixed(2)} />
          <Stat label="المدينة" value={user.city ?? "—"} />
          <Stat label="المنطقة" value={user.region ?? "—"} />
          <Stat label="الجنس" value={user.gender === "male" ? "ذكر" : user.gender === "female" ? "أنثى" : "—"} />
          <Stat label="سنة الميلاد" value={user.birth_year ? String(user.birth_year) : "—"} />
        </div>

        <div className="bg-canvas-well rounded-card p-5 border border-ink-line">
          <div className="text-[10px] font-bold uppercase tracking-wide text-ink-mute mb-1">
            بيانات الاتصال بالخدمة
          </div>
          <code className="text-[11px] text-ink-soft font-mono break-all" dir="ltr">
            {process.env.NEXT_PUBLIC_TRENDX_API ?? "https://trendx-production.up.railway.app"}
          </code>
        </div>
      </main>
    </>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-canvas-card rounded-card shadow-card p-4">
      <div className="text-[10px] font-bold uppercase tracking-wide text-ink-mute mb-1">{label}</div>
      <div className="text-base font-bold tabular text-ink">{value}</div>
    </div>
  );
}
