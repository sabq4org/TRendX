import type { Config } from "tailwindcss";

/**
 * TRENDX Dashboard — calm editorial palette.
 * Avoids screaming brand colors; relies on a near-white canvas with
 * generous whitespace, soft elevation, and accents reserved for data.
 */
const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Foreground inks (warm-cool blend, never pure black)
        ink: {
          DEFAULT: "#1A1B25",
          soft: "#3A3D4A",
          mute: "#6B6F7E",
          ghost: "#9AA0AE",
          line: "#E4E7F0",
        },
        // Canvas / surfaces
        canvas: {
          DEFAULT: "#FAFBFD",
          card: "#FFFFFF",
          well: "#F4F6FB",
          ring: "#EBEEF5",
        },
        // Brand — used sparingly, primarily for selected state + key bars
        brand: {
          50: "#EEF1FE",
          100: "#DDE3FD",
          300: "#9CABF5",
          500: "#4F66E1",
          600: "#3B4FCC",
          700: "#2C3DB0",
          900: "#1B2774",
        },
        // Data palette — distinct hues, balanced saturation
        data: {
          indigo: "#5C6BD0",
          violet: "#8869C9",
          rose: "#D26A8B",
          amber: "#E0A04B",
          teal: "#3CA597",
          emerald: "#3DA565",
          slate: "#6E7889",
        },
        success: { DEFAULT: "#1F9A65" },
        warn:    { DEFAULT: "#C7841F" },
        danger:  { DEFAULT: "#C44660" },
      },
      fontFamily: {
        sans: ["var(--font-cairo)", "var(--font-inter)", "system-ui", "sans-serif"],
        display: ["var(--font-cairo)", "var(--font-inter)", "system-ui", "sans-serif"],
        mono: ["ui-monospace", "SFMono-Regular", "monospace"],
      },
      fontSize: {
        "kpi": ["48px", { lineHeight: "1.05", letterSpacing: "-0.02em", fontWeight: "600" }],
        "kpi-sm": ["32px", { lineHeight: "1.05", letterSpacing: "-0.02em", fontWeight: "600" }],
      },
      boxShadow: {
        card: "0 1px 2px rgba(20,30,80,0.04), 0 1px 8px rgba(20,30,80,0.04)",
        "card-hover": "0 4px 12px rgba(20,30,80,0.08), 0 1px 4px rgba(20,30,80,0.06)",
        chip: "0 1px 0 rgba(20,30,80,0.04)",
      },
      borderRadius: {
        card: "14px",
        chip: "10px",
      },
      transitionTimingFunction: {
        soft: "cubic-bezier(0.22, 0.61, 0.36, 1)",
      },
    },
  },
  plugins: [],
};

export default config;
