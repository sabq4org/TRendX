"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  ListChecks,
  ClipboardList,
  Layers,
  UserCircle,
  TrendingUp,
} from "lucide-react";
import clsx from "clsx";

const NAV = [
  { href: "/overview", label: "النظرة العامة", icon: LayoutDashboard },
  { href: "/polls",    label: "الاستطلاعات",   icon: ListChecks },
  { href: "/surveys",  label: "الاستبيانات",   icon: ClipboardList },
  { href: "/sectors",  label: "القطاعات",      icon: Layers },
  { href: "/account",  label: "الحساب",         icon: UserCircle },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 shrink-0 border-l border-ink-line bg-canvas-card min-h-screen flex flex-col">
      <div className="px-6 pt-7 pb-8">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-xl bg-brand-500 text-white grid place-items-center shadow-card">
            <TrendingUp size={17} strokeWidth={2.6} />
          </div>
          <div className="flex flex-col">
            <span className="text-base font-bold tracking-tight">TRENDX</span>
            <span className="text-[10px] text-ink-mute -mt-0.5 font-medium">Publisher Console</span>
          </div>
        </div>
      </div>

      <nav className="px-3 flex-1">
        <ul className="space-y-0.5">
          {NAV.map((item) => {
            const active = pathname === item.href || pathname?.startsWith(item.href + "/");
            const Icon = item.icon;
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className={clsx(
                    "flex items-center gap-3 px-3.5 py-2.5 rounded-chip text-sm font-medium transition",
                    active
                      ? "bg-brand-50 text-brand-700"
                      : "text-ink-soft hover:bg-canvas-well hover:text-ink",
                  )}
                >
                  <Icon size={17} strokeWidth={active ? 2.4 : 2} />
                  <span>{item.label}</span>
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      <div className="px-5 pb-6 pt-4 border-t border-ink-line">
        <div className="bg-canvas-well rounded-chip p-3.5">
          <div className="text-[11px] font-semibold text-ink-soft mb-1.5">حالة النظام</div>
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-success animate-pulse" />
            <span className="text-xs text-ink-soft">متصل بـ Railway API</span>
          </div>
        </div>
      </div>
    </aside>
  );
}
