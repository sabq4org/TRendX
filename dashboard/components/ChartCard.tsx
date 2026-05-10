import type { ReactNode } from "react";
import clsx from "clsx";

type Props = {
  title: string;
  subtitle?: string;
  height?: number;
  className?: string;
  action?: ReactNode;
  eyebrow?: string;
  children: ReactNode;
};

export function ChartCard({
  title, subtitle, height = 300, className, action, eyebrow, children,
}: Props) {
  return (
    <div
      className={clsx(
        "bg-canvas-card rounded-card shadow-card p-7 hover:shadow-card-lift transition-shadow duration-500 ease-soft",
        className,
      )}
    >
      <div className="flex items-start justify-between mb-6 gap-4">
        <div className="flex-1 min-w-0">
          {eyebrow && (
            <div className="text-eyebrow text-brand-600 mb-1.5">{eyebrow}</div>
          )}
          <h3 className="text-base font-display font-bold text-ink tracking-tight">{title}</h3>
          {subtitle && (
            <p className="text-[12px] text-ink-mute mt-1 leading-relaxed">{subtitle}</p>
          )}
        </div>
        {action}
      </div>
      <div style={{ height }}>{children}</div>
    </div>
  );
}
