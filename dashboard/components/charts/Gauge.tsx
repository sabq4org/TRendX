"use client";

/**
 * Semi-circle gauge for sentiment / confidence scores 0-100.
 * Renders as an SVG so it scales crisply at any container size.
 */
export function Gauge({
  value, label, sub,
}: {
  value: number;
  label: string;
  sub?: string;
}) {
  const clamped = Math.max(0, Math.min(100, value));
  const angle = (clamped / 100) * 180;
  const radius = 90;
  const cx = 110;
  const cy = 110;
  const startAngle = 180;
  const endAngle = 180 - angle;

  const polar = (a: number) => ({
    x: cx + radius * Math.cos((a * Math.PI) / 180),
    y: cy - radius * Math.sin((a * Math.PI) / 180),
  });

  const start = polar(startAngle);
  const end = polar(endAngle);
  const largeArc = angle > 180 ? 1 : 0;

  // Colour ramp: red → amber → green
  const color = clamped >= 70 ? "#3DA565" : clamped >= 40 ? "#E0A04B" : "#D26A8B";

  return (
    <div className="flex flex-col items-center justify-center">
      <svg viewBox="0 0 220 130" width="100%" style={{ maxWidth: 280 }}>
        {/* Track */}
        <path
          d={`M ${polar(180).x} ${polar(180).y} A ${radius} ${radius} 0 0 1 ${polar(0).x} ${polar(0).y}`}
          fill="none"
          stroke="#EBEEF5"
          strokeWidth={14}
          strokeLinecap="round"
        />
        {/* Filled arc */}
        <path
          d={`M ${start.x} ${start.y} A ${radius} ${radius} 0 ${largeArc} 1 ${end.x} ${end.y}`}
          fill="none"
          stroke={color}
          strokeWidth={14}
          strokeLinecap="round"
        />
        {/* Center value */}
        <text
          x="50%" y="78%"
          textAnchor="middle"
          fontSize="34"
          fontWeight="700"
          fontFamily="var(--font-cairo)"
          fill="#1A1B25"
        >
          {clamped.toFixed(0)}
        </text>
      </svg>
      <div className="text-xs font-semibold text-ink-soft mt-1">{label}</div>
      {sub && <div className="text-[11px] text-ink-mute">{sub}</div>}
    </div>
  );
}
