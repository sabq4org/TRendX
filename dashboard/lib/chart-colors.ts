/**
 * Centralized data color palette. Picked so two adjacent series never read
 * as "the same blue", and so the color order is consistent across every
 * chart and tab in the dashboard.
 */

export const DATA_COLORS = {
  indigo: "#5C6BD0",
  violet: "#8869C9",
  rose: "#D26A8B",
  amber: "#E0A04B",
  teal: "#3CA597",
  emerald: "#3DA565",
  slate: "#6E7889",
};

export const DATA_PALETTE = [
  DATA_COLORS.indigo,
  DATA_COLORS.violet,
  DATA_COLORS.amber,
  DATA_COLORS.teal,
  DATA_COLORS.rose,
  DATA_COLORS.emerald,
  DATA_COLORS.slate,
];

export const HEATMAP_RAMP = [
  "#F4F6FB", // empty
  "#E0E5F8",
  "#C9D1F4",
  "#A8B5EC",
  "#8290DE",
  "#5C6BD0", // hot
];

export function colorAt(index: number): string {
  return DATA_PALETTE[index % DATA_PALETTE.length];
}
