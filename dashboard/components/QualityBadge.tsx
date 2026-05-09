import { Database, ShieldCheck, Target, Clock } from "lucide-react";
import { fmtInt, fmtRelativeNow } from "@/lib/format";

type Props = {
  sampleSize: number;
  confidenceLevel: number;
  marginOfError: number | null;
  representativenessScore?: number;
  dataFreshness: string;
  methodologyNote?: string;
};

export function QualityBadge({
  sampleSize, confidenceLevel, marginOfError, representativenessScore, dataFreshness, methodologyNote,
}: Props) {
  const items = [
    { icon: Database,    label: "حجم العيّنة",         value: fmtInt(sampleSize) },
    { icon: ShieldCheck, label: "مستوى الثقة",          value: `${confidenceLevel}%` },
    { icon: Target,      label: "هامش الخطأ",            value: marginOfError !== null ? `±${marginOfError}%` : "—" },
    representativenessScore !== undefined ? {
      icon: Target,      label: "تمثيل العيّنة",         value: `${representativenessScore}/100`,
    } : null,
    { icon: Clock,       label: "آخر تحديث",            value: fmtRelativeNow(dataFreshness) },
  ].filter(Boolean) as Array<{ icon: typeof Database; label: string; value: string }>;

  return (
    <div className="bg-canvas-card rounded-card shadow-card p-5">
      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-5 gap-x-6 gap-y-4">
        {items.map((item) => {
          const Icon = item.icon;
          return (
            <div key={item.label} className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-canvas-well grid place-items-center text-ink-mute">
                <Icon size={15} />
              </div>
              <div className="min-w-0">
                <div className="text-[10px] font-semibold uppercase tracking-wide text-ink-mute">
                  {item.label}
                </div>
                <div className="text-sm font-bold tabular text-ink mt-0.5">{item.value}</div>
              </div>
            </div>
          );
        })}
      </div>
      {methodologyNote && (
        <div className="mt-4 pt-4 border-t border-ink-line">
          <p className="text-[11px] text-ink-mute leading-relaxed">{methodologyNote}</p>
        </div>
      )}
    </div>
  );
}
