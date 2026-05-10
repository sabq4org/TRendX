import { Database, ShieldCheck, Target, Clock, Compass } from "lucide-react";
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
  sampleSize, confidenceLevel, marginOfError, representativenessScore,
  dataFreshness, methodologyNote,
}: Props) {
  const items = [
    { icon: Database,    label: "حجم العيّنة",    value: fmtInt(sampleSize),                                    accent: "sage" },
    { icon: ShieldCheck, label: "مستوى الثقة",     value: `${confidenceLevel}%`,                                 accent: "sage" },
    { icon: Target,      label: "هامش الخطأ",      value: marginOfError !== null ? `±${marginOfError}%` : "—",   accent: "gold" },
    representativenessScore !== undefined ? {
      icon: Compass,     label: "تمثيل العيّنة",   value: `${representativenessScore}/100`,                      accent: "copper",
    } : null,
    { icon: Clock,       label: "آخر تحديث",       value: fmtRelativeNow(dataFreshness),                          accent: "sage" },
  ].filter(Boolean) as Array<{ icon: typeof Database; label: string; value: string; accent: string }>;

  return (
    <div className="bg-canvas-card rounded-card shadow-card p-6 border border-ink-line/40">
      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-5 gap-x-8 gap-y-5">
        {items.map((item) => {
          const Icon = item.icon;
          const accentBg =
            item.accent === "sage"   ? "bg-sage-50 text-sage-700" :
            item.accent === "gold"   ? "bg-gold-50 text-gold-700" :
            "bg-copper-50 text-copper-700";
          return (
            <div key={item.label} className="flex items-center gap-3">
              <div className={`w-10 h-10 rounded-chip grid place-items-center ${accentBg}`}>
                <Icon size={16} strokeWidth={2.2} />
              </div>
              <div className="min-w-0">
                <div className="text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute">
                  {item.label}
                </div>
                <div className="text-base font-display font-bold tabular text-ink mt-0.5 leading-tight">
                  {item.value}
                </div>
              </div>
            </div>
          );
        })}
      </div>
      {methodologyNote && (
        <div className="mt-6 pt-5 border-t border-ink-line/40">
          <p className="text-[12px] text-ink-mute leading-relaxed font-light">{methodologyNote}</p>
        </div>
      )}
    </div>
  );
}
