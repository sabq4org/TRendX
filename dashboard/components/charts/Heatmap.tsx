"use client";

import clsx from "clsx";
import { fmtInt } from "@/lib/format";
import { HEATMAP_RAMP } from "@/lib/chart-colors";

type Cell = { x: string; y: string; count: number; row_pct: number };

/**
 * SVG-driven heatmap. Rows = y dimension, columns = x dimension.
 * Cell colour intensity scales with row_pct (0..100) so dominance
 * within each demographic slice is what we visualise — not raw count.
 */
export function Heatmap({
  xKeys,
  yKeys,
  cells,
  xLabel,
  yLabel,
}: {
  xKeys: string[];
  yKeys: string[];
  cells: Cell[];
  xLabel?: string;
  yLabel?: string;
}) {
  if (xKeys.length === 0 || yKeys.length === 0) {
    return (
      <div className="text-center py-12 text-sm text-ink-mute">
        لا توجد بيانات كافية لرسم الخريطة الحرارية بعد.
      </div>
    );
  }

  const lookup = new Map<string, Cell>();
  for (const c of cells) lookup.set(`${c.y}|${c.x}`, c);

  function colorFor(pct: number): string {
    if (pct <= 0) return HEATMAP_RAMP[0];
    const idx = Math.min(HEATMAP_RAMP.length - 1, Math.floor((pct / 100) * (HEATMAP_RAMP.length - 1)) + 1);
    return HEATMAP_RAMP[idx];
  }

  return (
    <div className="overflow-x-auto">
      <table className="border-separate border-spacing-1 mx-auto" dir="ltr">
        <thead>
          <tr>
            <th className="p-2 text-[10px] font-bold uppercase tracking-[0.14em] text-ink-mute">
              {yLabel ?? ""}
            </th>
            {xKeys.map((x) => (
              <th
                key={x}
                className="px-2 py-1 text-[11px] font-semibold text-ink-soft text-center min-w-[80px]"
              >
                {x}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {yKeys.map((y) => (
            <tr key={y}>
              <th
                scope="row"
                className="px-3 py-2 text-[11px] font-semibold text-ink-soft text-end whitespace-nowrap"
              >
                {y}
              </th>
              {xKeys.map((x) => {
                const cell = lookup.get(`${y}|${x}`);
                const pct = cell?.row_pct ?? 0;
                const count = cell?.count ?? 0;
                const dark = pct > 55;
                return (
                  <td
                    key={`${y}|${x}`}
                    className={clsx(
                      "rounded-chip text-center align-middle min-w-[80px] h-12 transition-transform hover:scale-105",
                      dark ? "text-canvas-card" : "text-ink",
                    )}
                    style={{ background: colorFor(pct) }}
                    title={`${y} × ${x} — ${pct}% (${count})`}
                  >
                    <div className="text-sm font-display font-bold tabular leading-tight">
                      {pct.toFixed(0)}%
                    </div>
                    <div className={clsx("text-[10px] tabular leading-none mt-0.5", dark ? "text-canvas-card/80" : "text-ink-mute")}>
                      {fmtInt(count)}
                    </div>
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
      {xLabel && (
        <div className="text-center mt-2 text-[10px] uppercase tracking-[0.14em] text-ink-mute">
          {xLabel}
        </div>
      )}
    </div>
  );
}
