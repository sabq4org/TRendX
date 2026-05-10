"use client";

import { useState } from "react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { useFetch } from "@/lib/use-fetch";
import { Header } from "@/components/Header";
import type { AudienceCriteria, AudienceEstimate } from "@/lib/types";
import { fmtInt } from "@/lib/format";
import { Users, MapPin, Smartphone, Calendar, Activity, Plus } from "lucide-react";
import clsx from "clsx";

const GENDERS = [
  { value: "male", label: "رجال" },
  { value: "female", label: "نساء" },
];
const AGE_GROUPS = ["18-24", "25-34", "35-44", "45-54", "55+"];
const CITIES = ["الرياض", "جدة", "الدمام", "مكة", "المدينة", "أبها", "الخبر", "الطائف"];
const DEVICES = [
  { value: "ios", label: "iPhone" },
  { value: "android", label: "أندرويد" },
  { value: "web", label: "الويب" },
];

export default function AudiencesPage() {
  const { token } = useAuth();
  const list = useFetch((t) => api.listAudiences(t), token);

  const [criteria, setCriteria] = useState<AudienceCriteria>({});
  const [name, setName] = useState("");
  const [estimate, setEstimate] = useState<AudienceEstimate | null>(null);
  const [estimating, setEstimating] = useState(false);
  const [creating, setCreating] = useState(false);

  function toggle<K extends keyof AudienceCriteria>(key: K, value: string) {
    const arr = (criteria[key] as string[] | undefined) ?? [];
    const next = arr.includes(value) ? arr.filter((x) => x !== value) : [...arr, value];
    setCriteria({ ...criteria, [key]: next.length > 0 ? next : undefined });
    setEstimate(null);
  }

  async function runEstimate() {
    if (!token) return;
    setEstimating(true);
    try {
      const e = await api.estimateAudience(token, criteria);
      setEstimate(e);
    } catch (err) {
      alert(err instanceof Error ? err.message : String(err));
    } finally {
      setEstimating(false);
    }
  }

  async function save() {
    if (!token || !name.trim()) return;
    setCreating(true);
    try {
      await api.createAudienceApi(token, { name: name.trim(), criteria });
      setName("");
      setCriteria({});
      setEstimate(null);
      list.refresh();
    } catch (err) {
      alert(err instanceof Error ? err.message : String(err));
    } finally {
      setCreating(false);
    }
  }

  return (
    <>
      <Header
        eyebrow="AUDIENCE MARKETPLACE"
        title="سوق الجمهور"
        subtitle="حدّد الشريحة المثاليّة لاستبيانك القادم وعرف فوراً عددها وسعرها."
      />
      <main className="flex-1 px-10 pb-10 space-y-7">
        {/* Builder */}
        <section className="bg-canvas-card rounded-card p-7 shadow-card-lift">
          <div className="flex items-center gap-2 mb-5">
            <Users size={16} className="text-brand-500" />
            <span className="text-eyebrow text-brand-600">أنشئ شريحة جديدة</span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-7">
            {/* Form */}
            <div className="space-y-5">
              <FilterGroup label="الجنس" icon={<Users size={14} />}>
                {GENDERS.map((g) => (
                  <Chip
                    key={g.value}
                    label={g.label}
                    active={(criteria.gender ?? []).includes(g.value)}
                    onClick={() => toggle("gender", g.value)}
                  />
                ))}
              </FilterGroup>

              <FilterGroup label="الفئة العمريّة" icon={<Calendar size={14} />}>
                {AGE_GROUPS.map((g) => (
                  <Chip
                    key={g}
                    label={g}
                    active={(criteria.age_groups ?? []).includes(g)}
                    onClick={() => toggle("age_groups", g)}
                  />
                ))}
              </FilterGroup>

              <FilterGroup label="المدن" icon={<MapPin size={14} />}>
                {CITIES.map((c) => (
                  <Chip
                    key={c}
                    label={c}
                    active={(criteria.cities ?? []).includes(c)}
                    onClick={() => toggle("cities", c)}
                  />
                ))}
              </FilterGroup>

              <FilterGroup label="الجهاز" icon={<Smartphone size={14} />}>
                {DEVICES.map((d) => (
                  <Chip
                    key={d.value}
                    label={d.label}
                    active={(criteria.devices ?? []).includes(d.value)}
                    onClick={() => toggle("devices", d.value)}
                  />
                ))}
              </FilterGroup>

              <button
                onClick={runEstimate}
                disabled={estimating}
                className="w-full brand-fill disabled:opacity-50 font-bold py-3 rounded-chip text-sm shadow-card hover:shadow-glow transition"
              >
                {estimating ? "جارٍ الحساب…" : "احسب التقدير"}
              </button>
            </div>

            {/* Estimate panel */}
            <div className="bg-canvas-well rounded-card p-6 border border-ink-hairline">
              {estimate ? (
                <div className="space-y-4">
                  <div className="text-eyebrow text-ai-700">نتيجة التقدير</div>
                  <div>
                    <div className="text-eyebrow text-ink-mute mb-1">المُطابقون</div>
                    <div className="text-kpi tabular text-brand-600">{fmtInt(estimate.available_count)}</div>
                  </div>
                  <div>
                    <div className="text-eyebrow text-ink-mute mb-1">السعر التقديري</div>
                    <div className="text-3xl font-display font-bold tabular text-ink">
                      {fmtInt(estimate.estimated_price_sar)} <span className="text-base text-ink-mute">ريال</span>
                    </div>
                    <div className="text-[11px] text-ink-mute">
                      {estimate.per_response_price_sar} ريال / إجابة · يصل تقريباً خلال {estimate.median_response_minutes} دقيقة
                    </div>
                  </div>
                  <div>
                    <div className="text-eyebrow text-ink-mute mb-1">التمثيلية</div>
                    <div className="flex items-center gap-2">
                      <div className="h-2 flex-1 bg-canvas-card rounded-pill overflow-hidden">
                        <div className="h-full bg-ai-gradient rounded-pill" style={{ width: `${Math.min(100, estimate.representativeness)}%` }} />
                      </div>
                      <span className="font-display font-bold text-sm tabular">{estimate.representativeness}%</span>
                    </div>
                  </div>
                  {estimate.available_count > 0 && (
                    <div className="pt-3 border-t border-ink-hairline">
                      <input
                        type="text"
                        placeholder="اسم الشريحة (مثال: شباب الرياض iOS)"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        className="w-full px-4 py-2.5 rounded-chip border border-ink-line bg-canvas-card text-sm focus:border-brand-500 focus:outline-none"
                      />
                      <button
                        onClick={save}
                        disabled={creating || !name.trim()}
                        className="w-full mt-2.5 bg-accent-500 hover:bg-accent-700 disabled:opacity-50 text-canvas-card font-bold py-2.5 rounded-chip text-sm transition flex items-center justify-center gap-1.5"
                      >
                        <Plus size={14} /> احفظ الشريحة
                      </button>
                    </div>
                  )}
                </div>
              ) : (
                <div className="h-full grid place-items-center text-center text-ink-mute py-12">
                  <div>
                    <Activity size={28} className="mx-auto mb-2 text-ink-ghost" />
                    <p className="text-sm">حدّد المعايير ثم اضغط <b>احسب التقدير</b></p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </section>

        {/* List of saved audiences */}
        <section className="bg-canvas-card rounded-card p-7 shadow-card">
          <h3 className="text-lg font-display font-bold text-ink mb-4">شرائحي المحفوظة</h3>
          {list.loading ? (
            <div className="h-24 rounded-chip shimmer" />
          ) : list.data && list.data.items.length > 0 ? (
            <ul className="divide-y divide-ink-hairline">
              {list.data.items.map((a) => (
                <li key={a.id} className="py-3 flex items-center gap-4">
                  <span className="font-display font-semibold text-ink flex-1">{a.name}</span>
                  <span className="text-[11px] text-ink-mute">{fmtInt(a.available_count)} مستجيب</span>
                  <span className="text-[11px] font-bold text-brand-600 tabular">
                    {fmtInt(a.estimated_price_sar)} ريال
                  </span>
                  <span className="text-[10px] font-bold uppercase tracking-[0.12em] text-ink-mute bg-canvas-well px-2 py-0.5 rounded-pill">
                    {a.status}
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-ink-mute">لا توجد شرائح محفوظة بعد.</p>
          )}
        </section>
      </main>
    </>
  );
}

function FilterGroup({
  label, icon, children,
}: { label: string; icon: React.ReactNode; children: React.ReactNode }) {
  return (
    <div>
      <div className="flex items-center gap-2 mb-2 text-ink-soft">
        {icon}
        <span className="text-eyebrow text-ink-soft">{label}</span>
      </div>
      <div className="flex flex-wrap gap-2">{children}</div>
    </div>
  );
}

function Chip({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={clsx(
        "px-3 py-1.5 rounded-pill text-xs font-bold border transition",
        active
          ? "bg-brand-500 text-canvas-card border-brand-500 shadow-glow"
          : "bg-canvas-card text-ink-soft border-ink-line hover:border-brand-300",
      )}
    >
      {label}
    </button>
  );
}
