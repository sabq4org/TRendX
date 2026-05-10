"use client";

import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";
import { ChartCard } from "@/components/ChartCard";
import { Heatmap } from "@/components/charts/Heatmap";
import { fmtInt } from "@/lib/format";
import type { Heatmap as HeatmapData, HeatmapDimension, Survey } from "@/lib/types";

const DIMS: { value: HeatmapDimension; label: string }[] = [
  { value: "gender",    label: "الجنس" },
  { value: "age_group", label: "الفئة العمريّة" },
  { value: "city",      label: "المدينة" },
  { value: "device",    label: "الجهاز" },
];

export function SurveyHeatmapsTab({ survey }: { survey: Survey }) {
  const { token } = useAuth();
  const [x, setX] = useState<HeatmapDimension>("gender");
  const [y, setY] = useState<HeatmapDimension>("age_group");
  const [questionId, setQuestionId] = useState<string>("");
  const [optionId, setOptionId] = useState<string>("");
  const [data, setData] = useState<HeatmapData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) return;
    let cancelled = false;
    setLoading(true);
    setError(null);
    api
      .surveyHeatmap(token, survey.id, x, y, questionId || undefined, optionId || undefined)
      .then((d) => { if (!cancelled) setData(d); })
      .catch((err) => { if (!cancelled) setError(err instanceof Error ? err.message : String(err)); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [token, survey.id, x, y, questionId, optionId]);

  const filteredQuestion = survey.questions.find((q) => q.id === questionId);

  return (
    <div className="space-y-5 stagger">
      <div className="bg-canvas-card rounded-card shadow-card p-6">
        <div className="text-eyebrow text-brand-600 mb-3">FILTERS</div>
        <h3 className="text-base font-display font-bold text-ink mb-5 tracking-tight">
          اختر بُعدين ديموغرافيّين، أو اربطهما بسؤال محدّد
        </h3>
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
          <Selector label="السطور (Y)" value={y} onChange={(v) => setY(v as HeatmapDimension)}
                    options={DIMS} />
          <Selector label="الأعمدة (X)" value={x} onChange={(v) => setX(v as HeatmapDimension)}
                    options={DIMS} />
          <Selector
            label="السؤال (اختياري)"
            value={questionId}
            onChange={(v) => { setQuestionId(v); setOptionId(""); }}
            options={[{ value: "", label: "كل المستجيبين" },
              ...survey.questions.map((q) => ({ value: q.id, label: q.title.slice(0, 50) }))]}
          />
          <Selector
            label="الخيار (اختياري)"
            value={optionId}
            onChange={setOptionId}
            disabled={!filteredQuestion}
            options={[{ value: "", label: "كل من أجاب" },
              ...(filteredQuestion?.options.map((o) => ({ value: o.id, label: o.text })) ?? [])]}
          />
        </div>
      </div>

      <ChartCard
        eyebrow="HEATMAP"
        title="خريطة حرارية ديموغرافيّة"
        subtitle={data ? `${fmtInt(data.total)} مستجيب — النسبة المعروضة هي حصّة الصف.` : undefined}
      >
        {loading && (
          <div className="h-72 grid place-items-center">
            <div className="w-8 h-8 rounded-full border-2 border-ink-line border-t-brand-500 animate-spin" />
          </div>
        )}
        {!loading && error && (
          <div className="text-center text-sm text-negative py-12">{error}</div>
        )}
        {!loading && !error && data && (
          <Heatmap
            xKeys={data.x_keys}
            yKeys={data.y_keys}
            cells={data.cells}
            xLabel={DIMS.find((d) => d.value === x)?.label}
            yLabel={DIMS.find((d) => d.value === y)?.label}
          />
        )}
      </ChartCard>
    </div>
  );
}

function Selector({
  label, value, onChange, options, disabled,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  options: Array<{ value: string; label: string }>;
  disabled?: boolean;
}) {
  return (
    <label className="block">
      <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute mb-1.5">
        {label}
      </div>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        disabled={disabled}
        className="w-full px-3 py-2.5 rounded-chip border border-ink-line bg-canvas-card focus:border-brand-500 focus:outline-none focus:ring-4 focus:ring-brand-500/15 text-sm transition disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>{o.label}</option>
        ))}
      </select>
    </label>
  );
}
