import clsx from "clsx";

type Props = {
  label: string;
  value: string | number;
  hint?: string;
  delta?: { value: number; trend: "up" | "down" | "flat" };
  size?: "default" | "small";
  accent?: "default" | "brand" | "success" | "warn";
};

export function KPICard({
  label, value, hint, delta, size = "default", accent = "default",
}: Props) {
  return (
    <div className="bg-canvas-card rounded-card shadow-card p-5">
      <div className="flex items-start justify-between mb-3">
        <span className="text-[11px] font-semibold uppercase tracking-wide text-ink-mute">
          {label}
        </span>
        {delta && (
          <span
            className={clsx(
              "text-[11px] font-bold tabular px-2 py-0.5 rounded-full",
              delta.trend === "up" && "text-success bg-success/10",
              delta.trend === "down" && "text-danger bg-danger/10",
              delta.trend === "flat" && "text-ink-mute bg-ink-line/40",
            )}
          >
            {delta.trend === "up" ? "▲" : delta.trend === "down" ? "▼" : "•"} {Math.abs(delta.value)}%
          </span>
        )}
      </div>
      <div
        className={clsx(
          "tabular leading-none",
          size === "small" ? "text-kpi-sm" : "text-kpi",
          accent === "brand" && "text-brand-600",
          accent === "success" && "text-success",
          accent === "warn" && "text-warn",
        )}
      >
        {value}
      </div>
      {hint && <div className="text-xs text-ink-mute mt-3 font-medium">{hint}</div>}
    </div>
  );
}
