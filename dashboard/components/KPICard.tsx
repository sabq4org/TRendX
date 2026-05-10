import clsx from "clsx";

type Tone = "default" | "brand" | "accent" | "ai";

type Props = {
  label: string;
  value: string | number;
  hint?: string;
  delta?: { value: number; trend: "up" | "down" | "flat" };
  size?: "hero" | "default" | "small";
  tone?: Tone;
  index?: number; // for the eyebrow numeral
};

const TONE_COLORS: Record<Tone, { bar: string; eyebrow: string; valueAccent?: string }> = {
  default: { bar: "text-ink-line",   eyebrow: "text-ink-mute" },
  brand:   { bar: "text-brand-500",  eyebrow: "text-brand-600" },
  accent:  { bar: "text-accent-500", eyebrow: "text-accent-700" },
  ai:      { bar: "text-ai-500",     eyebrow: "text-ai-700" },
};

export function KPICard({
  label, value, hint, delta, size = "default", tone = "default", index,
}: Props) {
  const colors = TONE_COLORS[tone];
  const numClass =
    size === "hero" ? "text-kpi-hero" :
    size === "small" ? "text-kpi-sm" :
    "text-kpi";

  return (
    <div className="relative bg-canvas-card rounded-card shadow-card hover:shadow-card-lift transition-all duration-500 ease-soft p-7 overflow-hidden group">
      {/* Vertical accent bar (uses currentColor via .accent-bar) */}
      <span className={clsx("accent-bar", colors.bar)} aria-hidden />

      {/* Eyebrow row */}
      <div className="flex items-start justify-between mb-5">
        <div className="flex items-center gap-2.5">
          {typeof index === "number" && (
            <span className={clsx("text-[10px] font-mono font-bold tabular", colors.eyebrow)}>
              {String(index + 1).padStart(2, "0")}
            </span>
          )}
          <span className="text-eyebrow text-ink-mute uppercase">
            {label}
          </span>
        </div>

        {delta && (
          <span
            className={clsx(
              "text-[11px] font-bold tabular px-2 py-0.5 rounded-pill",
              delta.trend === "up"   && "text-positive bg-positive-soft",
              delta.trend === "down" && "text-negative bg-negative-soft",
              delta.trend === "flat" && "text-ink-mute bg-canvas-well",
            )}
          >
            {delta.trend === "up" ? "▲" : delta.trend === "down" ? "▼" : "—"} {Math.abs(delta.value)}%
          </span>
        )}
      </div>

      {/* The number itself */}
      <div className={clsx("font-display tabular leading-none text-ink count-pop", numClass)}>
        {value}
      </div>

      {/* Hint */}
      {hint && (
        <div className="text-[12px] text-ink-mute mt-4 leading-relaxed font-medium">
          {hint}
        </div>
      )}
    </div>
  );
}
