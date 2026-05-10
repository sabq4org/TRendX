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
  Activity,
  Target,
  Users,
  TrendingUp,
} from "lucide-react";
import clsx from "clsx";
import { useAuth } from "@/lib/auth";
import { canAccess, type AccessGroup, type Role } from "@/lib/role-gate";

type NavItem = {
  href: string;
  label: string;
  icon: typeof LayoutDashboard;
  group: AccessGroup;
};

const NAV: NavItem[] = [
  { href: "/overview",         label: "النظرة العامة",  icon: LayoutDashboard,   group: "everyone" },
  { href: "/pulse",            label: "نبض اليوم",      icon: Activity,          group: "everyone" },
  { href: "/trendx-index",     label: "مؤشّر TRENDX",   icon: TrendingUp,        group: "everyone" },
  { href: "/polls",            label: "الاستطلاعات",   icon: ListChecks,        group: "publisher" },
  { href: "/surveys",          label: "الاستبيانات",   icon: ClipboardList,     group: "publisher" },
  { href: "/sectors",          label: "القطاعات",      icon: Layers,            group: "publisher" },
  { href: "/sectors/compare",  label: "مقارنة قطاعات",  icon: GitCompareArrows,  group: "publisher" },
  { href: "/audiences",        label: "سوق الجمهور",   icon: Users,             group: "publisher" },
  { href: "/accuracy",         label: "دقّة التنبّؤ",    icon: Target,            group: "everyone" },
  { href: "/account",          label: "الحساب",         icon: UserCircle,        group: "everyone" },
];

const ADMIN_ITEM: NavItem = {
  href: "/admin",
  label: "لوحة الإدارة",
  icon: ShieldCheck,
  group: "admin",
};

export function Sidebar() {
  const pathname = usePathname();
  const { user } = useAuth();
  const role = user?.role as Role | undefined;
  const visible = NAV.filter((item) => canAccess(role, item.group));

  return (
    <aside className="w-72 shrink-0 min-h-screen sticky top-0 h-screen flex flex-col p-5">
      <div className="glass rounded-card flex-1 flex flex-col p-6">
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

        <nav className="flex-1">
          <div className="text-[10px] font-bold uppercase tracking-[0.16em] text-ink-mute mb-3 px-3">
            القائمة
          </div>
          <ul className="space-y-1">
            {visible.map((item) => {
              const active =
                item.href === "/sectors"
                  ? pathname === "/sectors" ||
                    (pathname?.startsWith("/sectors/") && pathname !== "/sectors/compare")
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

            {canAccess(role, ADMIN_ITEM.group) && (
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

        <div className="mt-6 pt-6 border-t border-ink-line/60">
          <div className="flex items-center gap-2.5 px-2">
            <span className="relative flex w-2 h-2">
              <span className="absolute inset-0 rounded-full bg-brand-500 animate-ping opacity-60" />
              <span className="relative w-2 h-2 rounded-full bg-brand-500" />
            </span>
            <span className="text-[11px] font-bold text-brand-600">متصل بـ Railway</span>
            <span className="text-[10px] text-ink-mute ms-auto">v0.2</span>
          </div>
          {role === "respondent" && (
            <div className="mt-3 px-2 text-[10px] text-ink-mute leading-relaxed">
              يمكنك التصويت على نبض اليوم من تطبيق <b className="text-ink-soft">TRENDX</b> على iOS.
            </div>
          )}
        </div>
      </div>
    </aside>
  );
}
