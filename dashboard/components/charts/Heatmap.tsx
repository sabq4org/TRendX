"use client";

import { HEATMAP_RAMP } from "@/lib/chart-colors";

/**
 * Hour-of-day × day-of-week heatmap. Cells are tinted by frequency.
 * Used both for "votes by hour × day" and (later) for survey question ×
 * response correlations.
 */

type Cell = { row: string; col: string; value: number };

function colorFor(value: number, max: number): string {
  if (max === 0) return HEATMAP_RAMP[0];
  const idx = Math.min(HEATMAP_RAMP.length - 1, Math.round((value / max) * (HEATMAP_RAMP.length - 1)));
  return HEATMAP_RAMP[idx];
}

export function Heatmap({
  cells, rowLabels, colLabels,
}: {
  cells: Cell[];
  rowLabels: string[];
  colLabels: string[];
}) {
  const max = Math.max(0, ...cells.map((c) => c.value));
  const cellByKey = new Map(cells.map((c) => [`${c.row}-${c.col}`, c.value]));

  return (
    <div className="overflow-x-auto">
      <table className="border-separate border-spacing-1">
        <thead>
          <tr>
            <th className="w-16" />
            {colLabels.map((col) => (
              <th key={col} className="text-[10px] font-semibold text-ink-mute pb-1 px-1">
                {col}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rowLabels.map((row) => (
            <tr key={row}>
              <td className="text-[10px] font-semibold text-ink-soft pe-2 text-end">
                {row}
              </td>
              {colLabels.map((col) => {
                const v = cellByKey.get(`${row}-${col}`) ?? 0;
                return (
                  <td key={`${row}-${col}`}>
                    <div
                      title={`${row} • ${col}: ${v}`}
                      className="w-7 h-7 rounded-md transition hover:scale-110"
                      style={{ background: colorFor(v, max) }}
                    />
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>

      <div className="flex items-center gap-2 mt-3">
        <span className="text-[10px] text-ink-mute">قليل</span>
        <div className="flex gap-0.5">
          {HEATMAP_RAMP.map((c) => (
            <div key={c} className="w-4 h-2 rounded-sm" style={{ background: c }} />
          ))}
        </div>
        <span className="text-[10px] text-ink-mute">كثيف</span>
      </div>
    </div>
  );
}
