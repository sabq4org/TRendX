import type { ReactNode } from "react";
import clsx from "clsx";

type Props = {
  title: string;
  subtitle?: string;
  height?: number;
  className?: string;
  action?: ReactNode;
  children: ReactNode;
};

export function ChartCard({ title, subtitle, height = 280, className, action, children }: Props) {
  return (
    <div className={clsx("bg-canvas-card rounded-card shadow-card p-5", className)}>
      <div className="flex items-start justify-between mb-4 gap-3">
        <div>
          <h3 className="text-sm font-bold text-ink">{title}</h3>
          {subtitle && <p className="text-[11px] text-ink-mute mt-0.5">{subtitle}</p>}
        </div>
        {action}
      </div>
      <div style={{ height }}>{children}</div>
    </div>
  );
}
