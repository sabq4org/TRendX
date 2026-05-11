"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  Activity,
  ArrowRight,
  BarChart3,
  Gift,
  MapPin,
  Smartphone,
  Sparkles,
  TrendingUp,
  Users,
} from "lucide-react";
import { api } from "@/lib/api";
import type { AudienceStats } from "@/lib/api";
import { fmtInt } from "@/lib/format";

export default function BusinessPage() {
  const [stats, setStats] = useState<AudienceStats | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    const load = async () => {
      try {
        const data = await api.audienceStats();
        if (!cancelled) setStats(data);
      } catch (err) {
        if (!cancelled) setError(err instanceof Error ? err.message : String(err));
      }
    };
    load();
    // Refresh every 30s so the "live" framing actually feels live.
    const id = setInterval(load, 30_000);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, []);

  if (error) {
    return (
      <main className="min-h-screen grid place-items-center bg-canvas-deep">
        <div className="text-center">
          <div className="text-base font-bold text-ink">تعذّر تحميل البيانات</div>
          <div className="text-sm text-ink-mute mt-2">{error}</div>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-canvas-deep">
      {/* Top bar */}
      <header className="sticky top-0 z-20 bg-canvas-deep/85 backdrop-blur border-b border-ink-line">
        <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
          <Link href="/" className="text-base font-display font-black text-ink">
            TRENDX <span className="text-brand-500">للأعمال</span>
          </Link>
          <Link
            href="/login"
            className="text-[12px] font-bold text-brand-600 hover:text-brand-700"
          >
            دخول الناشرين ←
          </Link>
        </div>
      </header>

      {/* Hero */}
      <section className="max-w-6xl mx-auto px-6 pt-14 pb-10">
        <div className="text-eyebrow text-brand-600 mb-3 flex items-center gap-2">
          <Sparkles size={12} />
          نبض الرأي السعودي · بيانات حيّة
        </div>
        <h1 className="text-[40px] leading-[1.15] font-display font-black text-ink max-w-3xl">
          صل إلى{" "}
          <span className="text-brand-600">
            {stats ? fmtInt(stats.headline.total_users) : "—"}+
          </span>{" "}
          مستخدم سعودي يشاركون رأيهم يومياً.
        </h1>
        <p className="text-[15px] text-ink-mute mt-5 max-w-2xl leading-relaxed">
          منصة TRENDX تُنشئ بيانات رأي عالية الجودة عبر استطلاعات يومية، استبيانات
          عميقة، وتحدّيات تنبؤ أسبوعية. مع نظام مكافآت يضمن مشاركة حقيقية —
          ومجموعة سكانية متنوّعة جغرافياً وعمرياً وتقنياً.
        </p>

        <div className="mt-8 flex flex-wrap gap-3">
          <a
            href="mailto:business@trendx.sa?subject=طلب%20استبيان%20شركة"
            className="inline-flex items-center gap-2 text-[13px] font-bold px-5 py-3 rounded-pill bg-brand-500 text-white hover:bg-brand-600 transition shadow-card"
          >
            ابدأ حملتك مع TRENDX
            <ArrowRight size={14} className="rotate-180" />
          </a>
          <Link
            href="#audience"
            className="inline-flex items-center gap-2 text-[13px] font-bold px-5 py-3 rounded-pill border border-ink-line text-ink hover:border-brand-500 hover:text-brand-600 transition"
          >
            استكشف الجمهور
          </Link>
        </div>
      </section>

      {/* Live counters */}
      <section className="max-w-6xl mx-auto px-6 pb-10">
        <div className="text-eyebrow text-ink-mute mb-4 flex items-center gap-2">
          <Activity size={12} className="text-positive" />
          <span>محدّث الآن — يُجدَّد كل 30 ثانية</span>
          <span className="w-1.5 h-1.5 rounded-full bg-positive animate-pulse" />
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <StatTile
            icon={<Users size={16} />}
            label="مسجّلون"
            value={stats?.headline.total_users}
            hint="إجمالي قاعدة المستخدمين"
          />
          <StatTile
            icon={<Activity size={16} />}
            label="نشط هذا الأسبوع"
            value={stats?.headline.active_last_week}
            hint="فتح التطبيق آخر 7 أيام"
            tone="positive"
          />
          <StatTile
            icon={<TrendingUp size={16} />}
            label="تصويت اليوم"
            value={stats?.headline.votes_today}
            hint="أصوات في آخر 24 ساعة"
            tone="brand"
          />
          <StatTile
            icon={<Gift size={16} />}
            label="استبدال أسبوعياً"
            value={stats?.headline.redemptions_last_week}
            hint="نقاط حقيقية ⇄ هدايا"
            tone="accent"
          />
        </div>
      </section>

      {/* Audience composition */}
      <section id="audience" className="max-w-6xl mx-auto px-6 pb-14">
        <h2 className="text-[22px] font-display font-black text-ink mb-2">
          تركيبة الجمهور
        </h2>
        <p className="text-[13px] text-ink-mute mb-8 max-w-2xl">
          مَن يصلك حين تنشر استبياناً على TRENDX — هذه شريحة سكانية حقيقية،
          محسوبة من قاعدة المستخدمين والاستجابات اللحظية.
        </p>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <DemographicCard
            title="الفئات العمرية"
            subtitle="بناءً على إجاباتهم في الاستطلاعات"
            buckets={stats?.age ?? []}
            empty="—"
          />
          <DemographicCard
            title="أعلى المدن"
            subtitle="حسب موقع المستخدم"
            buckets={stats?.cities ?? []}
            empty="—"
            icon={<MapPin size={12} />}
          />
          <DemographicCard
            title="الجنس"
            subtitle="من معلومات الحساب"
            buckets={(stats?.gender ?? []).map((g) => ({
              ...g,
              key: genderLabel(g.key),
            }))}
            empty="—"
          />
          <DemographicCard
            title="الجهاز"
            subtitle="نقطة الاستخدام الأولى"
            buckets={(stats?.device ?? []).map((d) => ({
              ...d,
              key: deviceLabel(d.key),
            }))}
            empty="—"
            icon={<Smartphone size={12} />}
          />
        </div>
      </section>

      {/* Top topics */}
      {stats && stats.top_topics.length > 0 ? (
        <section className="max-w-6xl mx-auto px-6 pb-14">
          <h2 className="text-[22px] font-display font-black text-ink mb-2">
            أكثر القطاعات نشاطاً الآن
          </h2>
          <p className="text-[13px] text-ink-mute mb-6 max-w-2xl">
            القطاعات التي يُجرى عليها أكبر عدد من الاستطلاعات النشطة — مؤشّر
            للموضوعات التي تحظى بأعلى انخراط.
          </p>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {stats.top_topics.map((topic) => (
              <div
                key={topic.topic_id ?? topic.name}
                className="bg-canvas-card rounded-card border border-ink-line p-4"
              >
                <div className="text-[10px] font-bold text-ink-mute mb-1">قطاع</div>
                <div className="text-[14px] font-bold text-ink mb-3 truncate">
                  {topic.name}
                </div>
                <div className="flex items-baseline gap-1">
                  <span className="text-[22px] font-display font-black text-brand-600 tabular">
                    {fmtInt(topic.polls_count)}
                  </span>
                  <span className="text-[10px] text-ink-mute">استطلاع نشط</span>
                </div>
              </div>
            ))}
          </div>
        </section>
      ) : null}

      {/* Why TRENDX (pitch) */}
      <section className="max-w-6xl mx-auto px-6 pb-20">
        <div className="bg-gradient-to-br from-brand-500 to-ai-700 rounded-card text-white p-10">
          <h2 className="text-[24px] font-display font-black mb-6">
            لماذا تختار TRENDX لاستبيانات شركتك؟
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Pitch
              title="بيانات صادقة، مدفوعة"
              body="كل مشارك يحصل على نقاط قابلة للاستبدال — تصويتاً عابراً يتحوّل إلى مشاركة جدّية."
              icon={<BarChart3 size={16} />}
            />
            <Pitch
              title="استهداف ديموغرافي دقيق"
              body="استهدف بالعمر، المدينة، الجنس، أو الموضوعات التي يتابعها المستخدم. لا نسب مزوّرة."
              icon={<Users size={16} />}
            />
            <Pitch
              title="نتائج لحظية + AI"
              body="لوحة تحكم حيّة، تقارير ذكاء اصطناعي، ومقارنة قطاعية — كلها جاهزة قبل ما تنتهي الحملة."
              icon={<Sparkles size={16} />}
            />
          </div>
          <a
            href="mailto:business@trendx.sa?subject=طلب%20عرض%20سعر"
            className="mt-8 inline-flex items-center gap-2 text-[14px] font-bold px-6 py-3 rounded-pill bg-white text-brand-600 hover:bg-white/95 transition"
          >
            تواصل مع فريق الأعمال
            <ArrowRight size={14} className="rotate-180" />
          </a>
        </div>
      </section>

      <footer className="border-t border-ink-line py-6">
        <div className="max-w-6xl mx-auto px-6 text-[11px] text-ink-mute flex flex-wrap gap-4 justify-between">
          <div>© TRENDX — جميع الحقوق محفوظة</div>
          <div>الأرقام محدّثة في {stats ? new Date(stats.generated_at).toLocaleTimeString("ar", { hour: "2-digit", minute: "2-digit" }) : "—"}</div>
        </div>
      </footer>
    </main>
  );
}

// MARK: - Building blocks

function StatTile({
  icon,
  label,
  value,
  hint,
  tone = "ink",
}: {
  icon: React.ReactNode;
  label: string;
  value: number | undefined;
  hint: string;
  tone?: "ink" | "brand" | "positive" | "accent";
}) {
  const toneClass = {
    ink: "text-ink",
    brand: "text-brand-600",
    positive: "text-positive",
    accent: "text-accent-700",
  }[tone];
  return (
    <div className="bg-canvas-card rounded-card border border-ink-line p-5 shadow-card">
      <div className="flex items-center gap-2 mb-3 text-ink-mute">
        {icon}
        <span className="text-[11px] font-bold tracking-wide">{label}</span>
      </div>
      <div className={`text-[34px] font-display font-black tabular leading-none ${toneClass}`}>
        {value === undefined ? "—" : fmtInt(value)}
      </div>
      <div className="text-[11px] text-ink-mute mt-2">{hint}</div>
    </div>
  );
}

function DemographicCard({
  title,
  subtitle,
  buckets,
  empty,
  icon,
}: {
  title: string;
  subtitle: string;
  buckets: { key: string; count: number; percentage: number }[];
  empty: string;
  icon?: React.ReactNode;
}) {
  const total = buckets.reduce((sum, b) => sum + b.count, 0);
  return (
    <div className="bg-canvas-card rounded-card border border-ink-line p-6 shadow-card">
      <div className="text-eyebrow text-ink-mute mb-2 flex items-center gap-1.5">
        {icon}
        {title}
      </div>
      <div className="text-[12px] text-ink-mute mb-5">{subtitle}</div>
      {total === 0 ? (
        <div className="text-[12px] text-ink-ghost py-6 text-center">{empty}</div>
      ) : (
        <ul className="space-y-3">
          {buckets.slice(0, 6).map((b) => (
            <li key={b.key}>
              <div className="flex items-center justify-between text-[12px] mb-1.5">
                <span className="font-bold text-ink truncate">{b.key}</span>
                <span className="tabular text-ink-mute">
                  {fmtInt(b.count)} · {b.percentage.toFixed(1)}%
                </span>
              </div>
              <div className="h-2 rounded-full bg-canvas-well overflow-hidden">
                <div
                  className="h-full bg-brand-500 rounded-full transition-all"
                  style={{ width: `${Math.min(100, b.percentage)}%` }}
                />
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function Pitch({
  title,
  body,
  icon,
}: {
  title: string;
  body: string;
  icon: React.ReactNode;
}) {
  return (
    <div>
      <div className="w-10 h-10 rounded-full bg-white/15 grid place-items-center mb-3">
        {icon}
      </div>
      <div className="text-[15px] font-bold mb-1.5">{title}</div>
      <div className="text-[12.5px] text-white/82 leading-relaxed">{body}</div>
    </div>
  );
}

function genderLabel(key: string): string {
  switch (key) {
    case "male": return "ذكور";
    case "female": return "إناث";
    case "other": return "غير ذلك";
    default: return "غير محدّد";
  }
}

function deviceLabel(key: string): string {
  switch (key) {
    case "ios": return "iPhone";
    case "ipad": return "iPad";
    case "android": return "Android";
    case "web": return "Web";
    default: return "غير معروف";
  }
}
