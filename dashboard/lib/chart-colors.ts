/**
 * Chart palette — locked to the iOS TRENDX identity:
 *   1. brand blue    (#3B5BDB) — primary
 *   2. accent orange (#FA7C12) — secondary
 *   3. AI violet     (#7048E8) — tertiary, AI-touched
 *   4. AI cyan       (#1098AD) — quaternary, info accents
 *   5. brand light   (#4C6EF5) — supporting series
 *   6. accent deep   (#E8590C) — supporting warm
 *   7. AI indigo     (#4263EB) — supporting cool
 *   8. ink-soft      (#495057) — neutral fallback
 */

export const DATA_COLORS = {
  brand:       "#3B5BDB",
  accent:      "#FA7C12",
  aiViolet:    "#7048E8",
  aiCyan:      "#1098AD",
  brandLight:  "#4C6EF5",
  accentDeep:  "#E8590C",
  aiIndigo:    "#4263EB",
  inkSoft:     "#495057",
};

export const DATA_PALETTE = [
  DATA_COLORS.brand,
  DATA_COLORS.accent,
  DATA_COLORS.aiViolet,
  DATA_COLORS.aiCyan,
  DATA_COLORS.brandLight,
  DATA_COLORS.accentDeep,
  DATA_COLORS.aiIndigo,
  DATA_COLORS.inkSoft,
];

export const HEATMAP_RAMP = [
  "#F0F2FA", // empty (canvas-well)
  "#DCE3FE", // brand-100
  "#BFCAFD", // brand-200
  "#9EAFEC", // brand-300
  "#6B83E5", // brand-400
  "#3B5BDB", // brand-500 (hot)
];

export function colorAt(index: number): string {
  return DATA_PALETTE[index % DATA_PALETTE.length];
}
