"use client";

import {
  Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis,
} from "recharts";
import { fmtInt } from "@/lib/format";

type Datum = { day: string; value: number };

export function AreaTrend({ data, accent = "#3F6B4D" }: { data: Datum[]; accent?: string }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={data} margin={{ top: 8, right: 16, bottom: 8, left: 16 }}>
        <defs>
          <linearGradient id="areaTrendFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={accent} stopOpacity={0.32} />
            <stop offset="100%" stopColor={accent} stopOpacity={0.02} />
          </linearGradient>
        </defs>
        <CartesianGrid stroke="#EBEEF5" vertical={false} />
        <XAxis
          dataKey="day"
          stroke="#6B6F7E"
          fontSize={10}
          tickLine={false}
          axisLine={{ stroke: "#E4E7F0" }}
          reversed
          minTickGap={20}
        />
        <YAxis
          stroke="#6B6F7E"
          fontSize={11}
          tickLine={false}
          axisLine={false}
          orientation="right"
          tickFormatter={(v) => fmtInt(v as number)}
        />
        <Tooltip
          contentStyle={{
            borderRadius: 10, border: "1px solid #E4E7F0", fontSize: 12,
            fontFamily: "var(--font-cairo)", direction: "rtl",
          }}
          formatter={(v: number) => [fmtInt(v), "تراكمي"]}
        />
        <Area
          type="monotone"
          dataKey="value"
          stroke={accent}
          strokeWidth={2.2}
          fill="url(#areaTrendFill)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
