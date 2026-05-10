/**
 * Chart palette — derived from the Saudi-rooted brand system in
 * `tailwind.config.ts`. We export hex strings (rather than `tailwind`
 * tokens) because Recharts consumes raw colours, not utility classes.
 *
 * Order matters: the first colour is reserved for the primary series
 * (the "leading" data point), and successive colours fall back to
 * supporting hues that don't fight for attention.
 */

export const DATA_COLORS = {
  sage:        "#3F6B4D", // primary
  gold:        "#C9A961",
  copper:      "#B86F4A",
  sageLight:   "#7FA088",
  goldDark:    "#9F8240",
  copperDark:  "#8B5435",
  sageDeep:    "#1F4630",
  inkSoft:     "#34392F",
};

export const DATA_PALETTE = [
  DATA_COLORS.sage,
  DATA_COLORS.gold,
  DATA_COLORS.copper,
  DATA_COLORS.sageLight,
  DATA_COLORS.goldDark,
  DATA_COLORS.copperDark,
  DATA_COLORS.sageDeep,
  DATA_COLORS.inkSoft,
];

export const HEATMAP_RAMP = [
  "#F2EDDF", // empty
  "#E0E0CB",
  "#C2CBB4",
  "#9DB59A",
  "#6E957A",
  "#3F6B4D", // hot
];

export function colorAt(index: number): string {
  return DATA_PALETTE[index % DATA_PALETTE.length];
}
