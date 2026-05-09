"use client";

import { useAuth } from "@/lib/auth";
import { LogOut, BadgeCheck } from "lucide-react";
import { fmtInt } from "@/lib/format";

export function Header({ title, subtitle }: { title: string; subtitle?: string }) {
  const { user, signOut } = useAuth();

  const tierLabel = user?.tier === "enterprise"
    ? "Enterprise"
    : user?.tier === "premium"
      ? "Premium"
      : "Free";

  return (
    <header className="px-9 pt-8 pb-6 bg-canvas-card border-b border-ink-line">
      <div className="flex items-start justify-between gap-6">
        <div>
          <h1 className="text-[22px] font-bold tracking-tight text-ink leading-tight">{title}</h1>
          {subtitle && <p className="text-sm text-ink-mute mt-1.5">{subtitle}</p>}
        </div>

        {user && (
          <div className="flex items-center gap-4">
            <div className="text-left">
              <div className="text-xs font-semibold text-ink-soft">{user.name}</div>
              <div className="flex items-center gap-1.5 mt-0.5">
                <BadgeCheck size={12} className="text-brand-500" />
                <span className="text-[11px] text-ink-mute">{tierLabel}</span>
                <span className="text-ink-line">·</span>
                <span className="text-[11px] text-ink-mute tabular">{fmtInt(user.points)} نقطة</span>
              </div>
            </div>
            <div className="w-10 h-10 rounded-full bg-brand-100 text-brand-700 grid place-items-center font-bold">
              {user.avatar_initial || user.name.slice(0, 1)}
            </div>
            <button
              onClick={signOut}
              className="w-9 h-9 rounded-chip text-ink-mute hover:bg-canvas-well hover:text-danger grid place-items-center transition"
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
