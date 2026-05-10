"use client";

import Link from "next/link";
import { Users, FileText, Activity, ChevronLeft } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { Header } from "@/components/Header";

const SECTIONS = [
  {
    href: "/admin/users",
    title: "المستخدمون",
    description: "تصفّح، فلترة، وتعديل الباقات والأدوار.",
    icon: Users,
    color: "brand",
  },
  {
    href: "/admin/audit",
    title: "سجل التدقيق",
    description: "كل تعديل إداري، كل تسليم Webhook، تتبّع كامل.",
    icon: FileText,
    color: "accent",
  },
  {
    href: "/admin/jobs",
    title: "حالة المهام",
    description: "آخر snapshot، آخر تقرير AI، حالة Webhooks الحيّة.",
    icon: Activity,
    color: "ai",
  },
];

export default function AdminHomePage() {
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";

  return (
    <>
      <Header
        eyebrow="ADMIN CONSOLE"
        title="لوحة الإدارة"
        subtitle="مركز التحكّم في المنصّة — صلاحية الوصول مقصورة على فريق TRENDX."
      />
      <main className="flex-1 px-10 pb-10">
        {!isAdmin ? (
          <div className="bg-negative-soft border border-negative/20 rounded-card p-8 text-center">
            <p className="text-sm font-bold text-negative mb-1">صلاحية مطلوبة</p>
            <p className="text-xs text-ink-mute">هذه الصفحة متاحة فقط للحسابات بدور admin.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 stagger">
            {SECTIONS.map((s, i) => {
              const Icon = s.icon;
              const colorClasses = {
                brand:  { bg: "bg-brand-50",  text: "text-brand-600" },
                accent: { bg: "bg-accent-50", text: "text-accent-700" },
                ai:     { bg: "bg-ai-50",     text: "text-ai-700" },
              }[s.color] ?? { bg: "bg-canvas-well", text: "text-ink" };
              return (
                <Link
                  key={s.href}
                  href={s.href}
                  className="group bg-canvas-card rounded-card shadow-card hover:shadow-card-lift transition-all duration-500 ease-soft p-7 relative overflow-hidden"
                >
                  <div className="flex items-center justify-between mb-5">
                    <span className="text-[10px] font-mono font-bold tabular text-ink-mute">
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    <ChevronLeft className="text-ink-ghost group-hover:text-brand-600 group-hover:-translate-x-1 transition-transform" size={18} />
                  </div>
                  <div className={`w-12 h-12 rounded-chip ${colorClasses.bg} grid place-items-center mb-4`}>
                    <Icon size={20} className={colorClasses.text} />
                  </div>
                  <h3 className="text-xl font-display font-black text-ink tracking-tight mb-2">
                    {s.title}
                  </h3>
                  <p className="text-[13px] text-ink-mute leading-relaxed font-light">
                    {s.description}
                  </p>
                </Link>
              );
            })}
          </div>
        )}
      </main>
    </>
  );
}
