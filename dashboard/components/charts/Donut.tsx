"use client";

import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { DATA_PALETTE } from "@/lib/chart-colors";
import { fmtInt, fmtPctRaw } from "@/lib/format";

type Datum = { label: string; value: number; total?: number };

export function Donut({ data, totalLabel = "إجمالي" }: { data: Datum[]; totalLabel?: string }) {
  const total = data.reduce((acc, d) => acc + d.value, 0);

  return (
    <div className="relative w-full h-full">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius="62%"
            outerRadius="86%"
            paddingAngle={2}
            dataKey="value"
            stroke="#FFFFFF"
            strokeWidth={2}
          >
            {data.map((_, i) => (
              <Cell key={i} fill={DATA_PALETTE[i % DATA_PALETTE.length]} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              borderRadius: 10,
              border: "1px solid #E4E7F0",
              fontSize: 12,
              fontFamily: "var(--font-cairo)",
            }}
            formatter={(value: number, _name: string, payload) => {
              const datum = payload.payload as Datum;
              const pct = total > 0 ? (datum.value / total) * 100 : 0;
              return [`${fmtInt(value)}  ·  ${fmtPctRaw(pct, 1)}`, datum.label];
            }}
            labelFormatter={() => ""}
          />
        </PieChart>
      </ResponsiveContainer>

      {/* Center label */}
      <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
        <div className="text-[10px] font-bold uppercase tracking-[0.16em] text-ink-mute">
          {totalLabel}
        </div>
        <div className="text-3xl font-display font-black tabular text-ink mt-1 leading-none tracking-tight">
          {fmtInt(total)}
        </div>
      </div>

      {/* Legend below — proper RTL */}
      <ul className="absolute bottom-0 inset-x-0 flex flex-wrap justify-center gap-x-4 gap-y-1.5">
        {data.map((d, i) => (
          <li key={d.label} className="flex items-center gap-1.5 text-[11px] text-ink-soft">
            <span
              className="w-2 h-2 rounded-full"
              style={{ background: DATA_PALETTE[i % DATA_PALETTE.length] }}
            />
            <span>{d.label}</span>
            <span className="tabular text-ink-mute">{fmtInt(d.value)}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
