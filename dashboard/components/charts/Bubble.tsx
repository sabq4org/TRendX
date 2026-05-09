"use client";

import {
  CartesianGrid, ResponsiveContainer, Scatter, ScatterChart, Tooltip, XAxis, YAxis, ZAxis,
} from "recharts";
import { DATA_PALETTE } from "@/lib/chart-colors";

type Bubble = { name: string; x: number; y: number; size: number };

export function BubbleScatter({
  data, xLabel, yLabel,
}: {
  data: Bubble[];
  xLabel: string;
  yLabel: string;
}) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <ScatterChart margin={{ top: 16, right: 16, bottom: 24, left: 16 }}>
        <CartesianGrid stroke="#EBEEF5" />
        <XAxis
          type="number"
          dataKey="x"
          name={xLabel}
          stroke="#6B6F7E"
          fontSize={11}
          tickLine={false}
          axisLine={{ stroke: "#E4E7F0" }}
          reversed
          label={{ value: xLabel, position: "insideBottom", offset: -10, fill: "#6B6F7E", fontSize: 11 }}
        />
        <YAxis
          type="number"
          dataKey="y"
          name={yLabel}
          stroke="#6B6F7E"
          fontSize={11}
          tickLine={false}
          axisLine={false}
          orientation="right"
          label={{ value: yLabel, angle: -90, position: "insideRight", fill: "#6B6F7E", fontSize: 11 }}
        />
        <ZAxis type="number" dataKey="size" range={[80, 600]} />
        <Tooltip
          contentStyle={{
            borderRadius: 10, border: "1px solid #E4E7F0", fontSize: 12,
            fontFamily: "var(--font-cairo)", direction: "rtl",
          }}
          formatter={(v, name, payload) => {
            if (name === "x") return [v, xLabel];
            if (name === "y") return [v, yLabel];
            if (name === "size") return [v, "حجم العيّنة"];
            return [v, name];
          }}
          labelFormatter={(_, payload) => payload?.[0]?.payload?.name ?? ""}
          cursor={{ strokeDasharray: "3 3" }}
        />
        <Scatter data={data} fill={DATA_PALETTE[0]} fillOpacity={0.75} />
      </ScatterChart>
    </ResponsiveContainer>
  );
}
