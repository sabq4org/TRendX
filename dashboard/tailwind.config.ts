import type { Config } from "tailwindcss";

/**
 * TRENDX — "Saudi Premium" visual system.
 *
 *   - Warm cream canvas (paper, not pure white) so the eye relaxes on long
 *     sessions and the data carries the contrast.
 *   - A reserved palette built from three Saudi-rooted hues:
 *       sage   → derived from the Vision 2030 emerald, used for the
 *                primary brand and positive deltas
 *       gold   → desert / Najdi gold, used for accents, milestone chips,
 *                and warm highlights
 *       copper → muted clay tone, used as the secondary data colour and
 *                for cautionary states
 *   - Typography is hierarchical: huge tabular display numerals (96px+)
 *     paired with a single body face, with extreme weight contrast
 *     (200 vs 800) to give the layouts an editorial rhythm.
 */
const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // ----- Inks (warm-leaning charcoals) -----
        ink: {
          DEFAULT: "#1A1F1B",
          soft:    "#34392F",
          mute:    "#6E7269",
          ghost:   "#9CA098",
          line:    "#E5E1D5",
          hairline:"#EFEBDF",
        },
        // ----- Surfaces -----
        canvas: {
          DEFAULT: "#FAF6EC", // body cream (paper)
          card:    "#FFFFFF",
          well:    "#F2EDDF", // section sub-surface
          deep:    "#EDE6D2", // deeper grouping
          ring:    "#E5E1D5",
        },
        // ----- Sage / Saudi emerald -----
        sage: {
          50:  "#EAF1EB",
          100: "#D2E0D4",
          300: "#7FA088",
          500: "#3F6B4D",
          600: "#2D5A3D",
          700: "#1F4630",
          900: "#0F2D1E",
        },
        // ----- Gold (Najdi warm gold) -----
        gold: {
          50:  "#FBF3DC",
          100: "#F4E5B7",
          300: "#E0C77A",
          500: "#C9A961",
          700: "#9F8240",
          900: "#5C4A1E",
        },
        // ----- Copper / clay -----
        copper: {
          50:  "#F8EBE2",
          100: "#EDD2BF",
          300: "#D89F7E",
          500: "#B86F4A",
          700: "#8B5435",
          900: "#4C2E1D",
        },
        // ----- Semantic -----
        positive: { DEFAULT: "#3F6B4D", soft: "#EAF1EB" },
        negative: { DEFAULT: "#A33D3D", soft: "#F8E8E8" },
        warning:  { DEFAULT: "#9F8240", soft: "#FBF3DC" },
      },
      fontFamily: {
        sans: ["var(--font-tajawal)", "var(--font-inter)", "system-ui", "sans-serif"],
        display: ["var(--font-tajawal)", "system-ui", "sans-serif"],
        mono: ["var(--font-inter)", "ui-monospace", "monospace"],
      },
      fontSize: {
        // Editorial KPI scale
        "kpi-hero": ["96px", { lineHeight: "0.95", letterSpacing: "-0.035em", fontWeight: "800" }],
        "kpi":      ["64px", { lineHeight: "1.0",  letterSpacing: "-0.03em",  fontWeight: "800" }],
        "kpi-sm":   ["44px", { lineHeight: "1.05", letterSpacing: "-0.025em", fontWeight: "700" }],
        "kpi-mini": ["28px", { lineHeight: "1.1",  letterSpacing: "-0.015em", fontWeight: "700" }],
        // Body refinements
        "label":    ["10px", { lineHeight: "1.2", letterSpacing: "0.12em", fontWeight: "700" }],
        "eyebrow":  ["11px", { lineHeight: "1.3", letterSpacing: "0.16em", fontWeight: "700" }],
      },
      boxShadow: {
        // Shadows are sage-tinted (warm-cool), never neutral grey
        card: "0 1px 1px rgba(15,45,30,0.03), 0 4px 16px rgba(15,45,30,0.04)",
        "card-lift": "0 4px 8px rgba(15,45,30,0.05), 0 16px 40px rgba(15,45,30,0.08)",
        "card-deep": "0 12px 36px rgba(15,45,30,0.10)",
        glow: "0 0 0 6px rgba(63,107,77,0.06), 0 12px 32px rgba(63,107,77,0.10)",
        chip: "0 1px 0 rgba(15,45,30,0.04)",
        inset: "inset 0 1px 0 rgba(255,255,255,0.5), inset 0 -1px 0 rgba(15,45,30,0.04)",
      },
      borderRadius: {
        card: "20px",
        chip: "12px",
        pill: "999px",
      },
      backgroundImage: {
        "cream-warm":
          "radial-gradient(ellipse 80% 60% at 50% 0%, rgba(201,169,97,0.08) 0%, transparent 60%), linear-gradient(180deg, #FAF6EC 0%, #F2EDDF 100%)",
        "sage-glass":
          "linear-gradient(135deg, rgba(255,255,255,0.85) 0%, rgba(242,237,223,0.65) 100%)",
        "kpi-frame":
          "linear-gradient(180deg, #FFFFFF 0%, #FAF6EC 100%)",
        "hero":
          "radial-gradient(ellipse 120% 60% at 0% 0%, rgba(63,107,77,0.06) 0%, transparent 50%), radial-gradient(ellipse 80% 60% at 100% 100%, rgba(201,169,97,0.08) 0%, transparent 50%)",
      },
      transitionTimingFunction: {
        spring: "cubic-bezier(0.34, 1.56, 0.64, 1)",
        soft:   "cubic-bezier(0.22, 0.61, 0.36, 1)",
      },
      keyframes: {
        "fade-up": {
          "0%":   { opacity: "0", transform: "translateY(8px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "scale-in": {
          "0%":   { opacity: "0", transform: "scale(0.96)" },
          "100%": { opacity: "1", transform: "scale(1)" },
        },
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
