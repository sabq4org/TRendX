"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Search, ArrowLeft } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { Header } from "@/components/Header";
import { fmtInt } from "@/lib/format";
import type { AdminUser } from "@/lib/types";

const ROLES = ["", "respondent", "publisher", "admin"];
const TIERS = ["", "free", "premium", "enterprise"];

const ROLE_LABEL: Record<string, string> = {
  respondent: "مستجيب",
  publisher:  "ناشر",
  admin:      "إدارة",
};
const TIER_LABEL: Record<string, string> = {
  free:       "مجاني",
  premium:    "بريميوم",
  enterprise: "Enterprise",
};

export default function AdminUsersPage() {
  const { token, user: actor } = useAuth();
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [role, setRole] = useState("");
  const [tier, setTier] = useState("");

  async function load() {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      const result = await api.adminListUsers(token, {
        q: q || undefined,
        role: role || undefined,
        tier: tier || undefined,
        limit: 100,
      });
      setUsers(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token, q, role, tier]);

  async function changeRoleOrTier(id: string, body: { role?: string; tier?: string }) {
    if (!token) return;
    await api.adminUpdateUser(token, id, body);
    void load();
  }

  if (actor && actor.role !== "admin") {
    return (
      <>
        <Header eyebrow="ADMIN" title="المستخدمون" />
        <main className="px-10 pb-10">
          <div className="bg-negative-soft border border-negative/20 rounded-card p-8 text-sm text-negative text-center">
            صلاحية الإدارة مطلوبة.
          </div>
        </main>
      </>
    );
  }

  return (
    <>
      <Header
        eyebrow="ADMIN — USERS"
        title="إدارة المستخدمين"
        subtitle={`${fmtInt(users.length)} مستخدم في القائمة`}
        right={
          <Link
            href="/admin"
            className="inline-flex items-center gap-1.5 text-[11px] font-bold text-ink-mute hover:text-brand-600 transition"
          >
            <ArrowLeft size={12} className="rotate-180" /> العودة للوحة الإدارة
          </Link>
        }
      />
      <main className="flex-1 px-10 pb-10 space-y-5">
        {/* Filters */}
        <div className="bg-canvas-card rounded-card shadow-card p-5 grid grid-cols-1 md:grid-cols-3 gap-4">
          <label className="block">
            <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute mb-1.5">بحث</div>
            <div className="relative">
              <Search size={14} className="absolute end-3 top-1/2 -translate-y-1/2 text-ink-ghost" />
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="اسم أو بريد"
                className="w-full px-3 py-2.5 rounded-chip border border-ink-line bg-canvas-card focus:border-brand-500 focus:outline-none focus:ring-4 focus:ring-brand-500/15 text-sm transition"
              />
            </div>
          </label>
          <Select label="الدور" value={role} onChange={setRole}
                  options={ROLES.map((r) => ({ value: r, label: r ? (ROLE_LABEL[r] ?? r) : "كل الأدوار" }))} />
          <Select label="الباقة" value={tier} onChange={setTier}
                  options={TIERS.map((t) => ({ value: t, label: t ? (TIER_LABEL[t] ?? t) : "كل الباقات" }))} />
        </div>

        {/* Table */}
        <div className="bg-canvas-card rounded-card shadow-card overflow-hidden">
          {loading ? (
            <div className="p-16 text-center">
              <div className="w-8 h-8 mx-auto rounded-full border-2 border-ink-line border-t-brand-500 animate-spin" />
            </div>
          ) : error ? (
            <div className="p-12 text-center text-negative text-sm">{error}</div>
          ) : users.length === 0 ? (
            <div className="p-16 text-center text-sm text-ink-mute">لا نتائج تطابق البحث.</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-[10px] uppercase tracking-[0.14em] text-ink-mute border-b border-ink-line/40">
                  <tr>
                    <th className="px-6 py-4 text-start font-bold">المستخدم</th>
                    <th className="px-5 py-4 text-start font-bold">الموقع</th>
                    <th className="px-5 py-4 text-start font-bold">الدور</th>
                    <th className="px-5 py-4 text-start font-bold">الباقة</th>
                    <th className="px-5 py-4 text-end font-bold">النقاط</th>
                    <th className="px-5 py-4 text-end font-bold">آخر نشاط</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((u) => (
                    <tr key={u.id} className="border-b border-ink-line/30 hover:bg-canvas-well/50 transition">
                      <td className="px-6 py-4">
                        <div className="font-bold text-ink">{u.name}</div>
                        <div className="text-[11px] font-mono text-ink-mute">{u.email}</div>
                      </td>
                      <td className="px-5 py-4 text-[12px] text-ink-soft">
                        {u.city ?? "—"}{u.country ? ` · ${u.country}` : ""}
                      </td>
                      <td className="px-5 py-4">
                        <select
                          value={u.role}
                          onChange={(e) => changeRoleOrTier(u.id, { role: e.target.value })}
                          className="bg-canvas-well rounded-chip px-2 py-1 text-[12px] font-semibold text-ink border border-transparent hover:border-ink-line transition"
                        >
                          {ROLES.filter(Boolean).map((r) => (
                            <option key={r} value={r}>{ROLE_LABEL[r]}</option>
                          ))}
                        </select>
                      </td>
                      <td className="px-5 py-4">
                        <select
                          value={u.tier}
                          onChange={(e) => changeRoleOrTier(u.id, { tier: e.target.value })}
                          className="bg-canvas-well rounded-chip px-2 py-1 text-[12px] font-semibold text-ink border border-transparent hover:border-ink-line transition"
                        >
                          {TIERS.filter(Boolean).map((t) => (
                            <option key={t} value={t}>{TIER_LABEL[t]}</option>
                          ))}
                        </select>
                      </td>
                      <td className="px-5 py-4 text-end tabular text-ink">{fmtInt(u.points)}</td>
                      <td className="px-5 py-4 text-end text-[11px] text-ink-mute">
                        {new Date(u.last_active_at).toLocaleDateString("en-US")}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </main>
    </>
  );
}

function Select({
  label, value, onChange, options,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  options: Array<{ value: string; label: string }>;
}) {
  return (
    <label className="block">
      <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute mb-1.5">
        {label}
      </div>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-3 py-2.5 rounded-chip border border-ink-line bg-canvas-card focus:border-brand-500 focus:outline-none focus:ring-4 focus:ring-brand-500/15 text-sm transition"
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>{o.label}</option>
        ))}
      </select>
    </label>
  );
}
