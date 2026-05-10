"use client";

import { fmtInt, fmtPctRaw } from "@/lib/format";

type Datum = { label: string; value: number; subValue?: string };

/**
 * Horizontal bar chart — each bar is sized as a percentage of the maximum
 * value in the dataset (matches the spec: "ALWAYS scale bars relative to
 * the maximum value, never relative to each other without a shared axis").
 *
 * RTL-aware: bars grow from the right edge.
 */
export function HBar({ data, accent = "#3F6B4D" }: { data: Datum[]; accent?: string }) {
  const max = Math.max(1, ...data.map((d) => d.value));
  const total = data.reduce((acc, d) => acc + d.value, 0);

  return (
    <ul className="space-y-3">
      {data.map((row, i) => {
        const widthPct = (row.value / max) * 100;
        const sharePct = total > 0 ? (row.value / total) * 100 : 0;
        return (
          <li key={`${row.label}-${i}`}>
            <div className="flex items-center justify-between text-xs mb-1">
              <span className="font-medium text-ink-soft truncate max-w-[60%]">{row.label}</span>
              <span className="font-bold tabular text-ink">
                {fmtInt(row.value)}
                {total > 0 && (
                  <span className="text-ink-mute font-medium me-1.5">
                    {" "}· {fmtPctRaw(sharePct, 1)}
                  </span>
                )}
              </span>
            </div>
            <div className="h-2.5 rounded-full bg-canvas-well overflow-hidden">
              <div
                className="h-full rounded-full transition-all duration-500 ease-out"
                style={{ width: `${widthPct}%`, background: accent }}
              />
            </div>
            {row.subValue && (
              <div className="text-[10px] text-ink-mute mt-1">{row.subValue}</div>
            )}
          </li>
        );
      })}
    </ul>
  );
}
