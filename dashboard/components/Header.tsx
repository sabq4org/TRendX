"use client";

import { useAuth } from "@/lib/auth";
import { LogOut, BadgeCheck } from "lucide-react";
import { fmtInt } from "@/lib/format";

const TIER_LABEL = {
  enterprise: "Enterprise",
  premium: "Premium",
  free: "Free",
} as const;

export function Header({ title, subtitle, eyebrow }: {
  title: string;
  subtitle?: string;
  eyebrow?: string;
}) {
  const { user, signOut } = useAuth();

  return (
    <header className="px-10 pt-10 pb-8">
      <div className="flex items-end justify-between gap-6">
        <div className="flex-1 min-w-0">
          {eyebrow && (
            <div className="text-[11px] font-bold uppercase tracking-[0.22em] text-brand-600 mb-3">
              {eyebrow}
            </div>
          )}
          <h1 className="text-4xl lg:text-5xl font-display font-black tracking-tight text-ink leading-[1.05]">
            {title}
          </h1>
          {subtitle && (
            <p className="text-base text-ink-soft mt-3 max-w-2xl leading-relaxed font-light">
              {subtitle}
            </p>
          )}
        </div>

        {user && (
          <div className="flex items-center gap-4 shrink-0">
            <div className="text-end">
              <div className="text-sm font-bold text-ink">{user.name}</div>
              <div className="flex items-center gap-1.5 mt-1 justify-end">
                <BadgeCheck size={11} className="text-brand-500" />
                <span className="text-[11px] font-bold text-brand-600">
                  {TIER_LABEL[user.tier as keyof typeof TIER_LABEL] ?? "Free"}
                </span>
                <span className="text-ink-line">•</span>
                <span className="text-[11px] tabular text-ink-mute">{fmtInt(user.points)} نقطة</span>
              </div>
            </div>
            <div className="w-11 h-11 rounded-full bg-brand-600 text-canvas-card grid place-items-center font-display font-bold text-base shadow-card">
              {user.avatar_initial || user.name.slice(0, 1)}
            </div>
            <button
              onClick={signOut}
              className="w-10 h-10 rounded-chip border border-ink-line/60 bg-canvas-card/50 text-ink-mute hover:bg-negative/5 hover:text-negative hover:border-negative/30 grid place-items-center transition"
              title="تسجيل الخروج"
            >
              <LogOut size={15} />
            </button>
          </div>
        )}
      </div>
    </header>
  );
}
