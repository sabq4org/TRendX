import type { Config } from "tailwindcss";

/**
 * TRENDX — Dashboard visual system, locked to the iOS app's identity
 * (`TRENDX/Theme/TrendXTheme.swift`).
 *
 *   - Canvas: cool light grey-blue (#F4F5FA), the same surface used as
 *     `TrendXTheme.background` on iPhone — the dashboard must feel like
 *     a continuation of the same product, not a separate website.
 *   - Brand: TRENDX blue scale built around #3B5BDB / #364FC7. This is
 *     the only colour reserved for primary CTAs, leading data points,
 *     and active navigation.
 *   - Accent: warm orange (#FA7C12) used sparingly for milestone chips
 *     and secondary KPIs, matching iOS `TrendXTheme.accent`.
 *   - AI signature: violet `#7048E8` + cyan `#1098AD`, mirroring the
 *     iOS AI gradient. Used for AI-touched surfaces only.
 */
const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // ----- Inks -----
        ink: {
          DEFAULT:  "#1A1B25",
          soft:     "#495057",
          mute:     "#868E96",
          ghost:    "#ADB5BD",
          line:     "#DEE2E6",
          hairline: "#E4E7F5",
        },
        // ----- Surfaces -----
        canvas: {
          DEFAULT: "#F4F5FA", // body — matches iOS TrendXTheme.background
          card:    "#FFFFFF",
          well:    "#F0F2FA", // sub-surface (paleFill)
          deep:    "#E8EAF2", // backgroundDeep
          ring:    "#DEE2E6",
          soft:    "#E4E7F5",
        },
        // ----- Brand: TRENDX blue -----
        brand: {
          50:  "#EEF1FE",
          100: "#DCE3FE",
          200: "#BFCAFD",
          300: "#9EAFEC",
          400: "#6B83E5",
          500: "#3B5BDB", // ⭐ primary (TrendXTheme.primary)
          600: "#364FC7", // primaryDeep
          700: "#2A3FA5",
          800: "#1F2F84",
          900: "#1A2870",
        },
        // ----- Accent: warm orange -----
        accent: {
          50:  "#FFF4E6",
          100: "#FFE0B3",
          300: "#FFB066",
          500: "#FA7C12", // (TrendXTheme.accent)
          700: "#E8590C", // accentDeep
          900: "#A33C04",
        },
        // ----- AI signature -----
        ai: {
          indigo: "#4263EB",
          violet: "#7048E8",
          cyan:   "#1098AD",
          50:     "#F1EDFE",
          100:    "#E0D5FB",
          500:    "#7048E8",
          700:    "#5028B0",
        },
        // ----- Semantic — iOS aligned -----
        positive: { DEFAULT: "#2F9E44", soft: "#E5F4E8" },
        negative: { DEFAULT: "#E03131", soft: "#FBE4E4" },
        warning:  { DEFAULT: "#F59F00", soft: "#FEF3D7" },
        info:     { DEFAULT: "#1971C2", soft: "#E0EEFB" },
      },
      fontFamily: {
        sans: ["var(--font-tajawal)", "var(--font-inter)", "system-ui", "sans-serif"],
        display: ["var(--font-tajawal)", "system-ui", "sans-serif"],
        mono: ["var(--font-inter)", "ui-monospace", "monospace"],
      },
      fontSize: {
        "kpi-hero": ["96px", { lineHeight: "0.95", letterSpacing: "-0.035em", fontWeight: "800" }],
        "kpi":      ["64px", { lineHeight: "1.0",  letterSpacing: "-0.03em",  fontWeight: "800" }],
        "kpi-sm":   ["44px", { lineHeight: "1.05", letterSpacing: "-0.025em", fontWeight: "700" }],
        "kpi-mini": ["28px", { lineHeight: "1.1",  letterSpacing: "-0.015em", fontWeight: "700" }],
        "label":    ["10px", { lineHeight: "1.2", letterSpacing: "0.12em", fontWeight: "700" }],
        "eyebrow":  ["11px", { lineHeight: "1.3", letterSpacing: "0.16em", fontWeight: "700" }],
      },
      boxShadow: {
        // Brand-blue tinted shadows (iOS TrendXTheme.shadow)
        card:        "0 1px 1px rgba(59,91,219,0.04), 0 4px 16px rgba(59,91,219,0.05)",
        "card-lift": "0 4px 8px rgba(59,91,219,0.06), 0 16px 40px rgba(59,91,219,0.10)",
        "card-deep": "0 12px 36px rgba(54,79,199,0.14)",
        glow:        "0 0 0 6px rgba(59,91,219,0.08), 0 12px 32px rgba(59,91,219,0.18)",
        chip:        "0 1px 0 rgba(59,91,219,0.04)",
        inset:       "inset 0 1px 0 rgba(255,255,255,0.5), inset 0 -1px 0 rgba(59,91,219,0.04)",
      },
      borderRadius: {
        card: "20px",
        chip: "12px",
        pill: "999px",
      },
      backgroundImage: {
        "canvas-glow":
          "radial-gradient(ellipse 60% 40% at 0% 0%, rgba(59,91,219,0.08) 0%, transparent 60%), radial-gradient(ellipse 60% 40% at 100% 100%, rgba(250,124,18,0.06) 0%, transparent 60%)",
        "ai-gradient":
          "linear-gradient(135deg, #4263EB 0%, #7048E8 50%, #1098AD 100%)",
        "brand-gradient":
          "linear-gradient(135deg, #3B5BDB 0%, #4C6EF5 100%)",
        "hero":
          "radial-gradient(ellipse 120% 60% at 0% 0%, rgba(59,91,219,0.10) 0%, transparent 50%), radial-gradient(ellipse 80% 60% at 100% 100%, rgba(112,72,232,0.08) 0%, transparent 50%)",
      },
      transitionTimingFunction: {
        spring: "cubic-bezier(0.34, 1.56, 0.64, 1)",
        soft:   "cubic-bezier(0.22, 0.61, 0.36, 1)",
      },
      keyframes: {
        "fade-up":  { "0%": { opacity: "0", transform: "translateY(8px)" },  "100%": { opacity: "1", transform: "translateY(0)" } },
        "scale-in": { "0%": { opacity: "0", transform: "scale(0.96)" },     "100%": { opacity: "1", transform: "scale(1)" } },
      },
      animation: {
        "fade-up": "fade-up 0.5s cubic-bezier(0.22,0.61,0.36,1) both",
        "scale-in": "scale-in 0.4s cubic-bezier(0.34,1.56,0.64,1) both",
      },
    },
  },
  plugins: [],
};

export default config;
