"use client";

import {
  Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis,
} from "recharts";
import { DATA_PALETTE } from "@/lib/chart-colors";
import { fmtInt } from "@/lib/format";

export function StackedBar({
  data, seriesKeys,
}: {
  data: Array<Record<string, string | number>>;
  seriesKeys: string[];
}) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={data} margin={{ top: 8, right: 16, bottom: 8, left: 16 }}>
        <CartesianGrid stroke="#EBEEF5" vertical={false} />
        <XAxis
          dataKey="group"
          stroke="#6B6F7E"
          fontSize={11}
          tickLine={false}
          axisLine={{ stroke: "#E4E7F0" }}
          reversed
        />
        <YAxis
          stroke="#6B6F7E"
          fontSize={11}
          tickLine={false}
          axisLine={false}
          orientation="right"
        />
        <Tooltip
          contentStyle={{
            borderRadius: 10, border: "1px solid #E4E7F0", fontSize: 12,
            fontFamily: "var(--font-cairo)", direction: "rtl",
          }}
          cursor={{ fill: "rgba(92,107,208,0.06)" }}
          formatter={(v: number) => fmtInt(v)}
        />
        <Legend
          wrapperStyle={{ fontSize: 11, paddingTop: 8 }}
          formatter={(value) => <span className="text-ink-soft">{value}</span>}
        />
        {seriesKeys.map((key, i) => (
          <Bar
            key={key}
            dataKey={key}
            stackId="a"
            fill={DATA_PALETTE[i % DATA_PALETTE.length]}
            maxBarSize={36}
          />
        ))}
      </BarChart>
    </ResponsiveContainer>
  );
}
