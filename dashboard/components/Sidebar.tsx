"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  ListChecks,
  ClipboardList,
  Layers,
  GitCompareArrows,
  UserCircle,
  ShieldCheck,
} from "lucide-react";
import clsx from "clsx";
import { useAuth } from "@/lib/auth";

const NAV = [
  { href: "/overview",         label: "النظرة العامة", icon: LayoutDashboard },
  { href: "/polls",            label: "الاستطلاعات",   icon: ListChecks },
  { href: "/surveys",          label: "الاستبيانات",   icon: ClipboardList },
  { href: "/sectors",          label: "القطاعات",      icon: Layers },
  { href: "/sectors/compare",  label: "مقارنة قطاعات",  icon: GitCompareArrows },
  { href: "/account",          label: "الحساب",         icon: UserCircle },
];

const ADMIN_ITEM = { href: "/admin", label: "لوحة الإدارة", icon: ShieldCheck };

export function Sidebar() {
  const pathname = usePathname();
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";

  return (
    <aside className="w-72 shrink-0 min-h-screen sticky top-0 h-screen flex flex-col p-5">
      {/* Glass surface */}
      <div className="glass rounded-card flex-1 flex flex-col p-6">
        {/* Brand mark */}
        <Link href="/overview" className="block mb-9 group">
          <div className="flex items-baseline gap-2">
            <span className="text-3xl font-display font-black tracking-tight text-ink leading-none">
              TRENDX
            </span>
            <span className="w-1.5 h-1.5 rounded-full bg-brand-500 mt-1 group-hover:scale-125 transition" />
          </div>
          <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-brand-600 mt-2">
            ذكاء الرأي السعودي
          </p>
        </Link>

        {/* Nav */}
        <nav className="flex-1">
          <div className="text-[10px] font-bold uppercase tracking-[0.16em] text-ink-mute mb-3 px-3">
            القائمة
          </div>
          <ul className="space-y-1">
            {NAV.map((item) => {
              // Use exact match for /sectors so /sectors/compare doesn't
              // light up the parent sector page too.
              const active =
                item.href === "/sectors"
                  ? pathname === "/sectors" || (pathname?.startsWith("/sectors/") && pathname !== "/sectors/compare")
                  : pathname === item.href || pathname?.startsWith(item.href + "/");
              const Icon = item.icon;
              return (
                <li key={item.href}>
                  <Link
                    href={item.href}
                    className={clsx(
                      "relative flex items-center gap-3 px-3.5 py-3 rounded-chip text-sm font-medium transition group",
                      active
                        ? "brand-fill shadow-glow"
                        : "text-ink-soft hover:bg-canvas-well/70 hover:text-ink",
                    )}
                  >
                    <Icon size={17} strokeWidth={active ? 2.4 : 2} />
                    <span className="font-semibold">{item.label}</span>
                    {active && (
                      <span className="ms-auto w-1.5 h-1.5 rounded-full bg-accent-500 shadow-[0_0_0_3px_rgba(250,124,18,0.30)]" />
                    )}
                  </Link>
                </li>
              );
            })}

            {isAdmin && (
              <>
                <li className="pt-3">
                  <div className="text-[10px] font-bold uppercase tracking-[0.16em] text-ink-mute px-3 mb-2">
                    إدارة
                  </div>
                </li>
                <li>
                  {(() => {
                    const Icon = ADMIN_ITEM.icon;
                    const active = pathname?.startsWith("/admin");
                    return (
                      <Link
                        href={ADMIN_ITEM.href}
                        className={clsx(
                          "relative flex items-center gap-3 px-3.5 py-3 rounded-chip text-sm font-medium transition group",
                          active
                            ? "bg-accent-500 text-canvas-card shadow-card-lift"
                            : "text-ink-soft hover:bg-canvas-well/70 hover:text-ink",
                        )}
                      >
                        <Icon size={17} strokeWidth={active ? 2.4 : 2} />
                        <span className="font-semibold">{ADMIN_ITEM.label}</span>
                      </Link>
                    );
                  })()}
                </li>
              </>
            )}
          </ul>
        </nav>

        {/* Live status pill */}
        <div className="mt-6 pt-6 border-t border-ink-line/60">
          <div className="flex items-center gap-2.5 px-2">
            <span className="relative flex w-2 h-2">
              <span className="absolute inset-0 rounded-full bg-brand-500 animate-ping opacity-60" />
              <span className="relative w-2 h-2 rounded-full bg-brand-500" />
            </span>
            <span className="text-[11px] font-bold text-brand-600">متصل بـ Railway</span>
            <span className="text-[10px] text-ink-mute ms-auto">v0.2</span>
          </div>
        </div>
      </div>
    </aside>
  );
}
