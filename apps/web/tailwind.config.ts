import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: "1rem",
        sm: "1.5rem",
        lg: "2rem",
      },
      screens: {
        "2xl": "1280px",
      },
    },
    extend: {
      fontFamily: {
        sans: ["var(--font-sans)", "ui-sans-serif", "system-ui", "sans-serif"],
        display: ["var(--font-display)", "var(--font-sans)", "ui-sans-serif", "sans-serif"],
      },
      colors: {
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        text: "hsl(var(--text))",
        "text-muted": "hsl(var(--text-muted))",

        surface: "hsl(var(--surface))",
        "surface-2": "hsl(var(--surface-2))",
        "surface-3": "hsl(var(--surface-3))",

        border: "hsl(var(--border))",
        "border-strong": "hsl(var(--border-strong))",
        ring: "hsl(var(--ring))",

        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
          hover: "hsl(var(--primary-hover))",
          light: "hsl(var(--primary-light))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
          hover: "hsl(var(--accent-hover))",
          light: "hsl(var(--accent-light))",
        },

        success: {
          DEFAULT: "hsl(var(--success))",
          bg: "hsl(var(--success-bg))",
        },
        warning: {
          DEFAULT: "hsl(var(--warning))",
          bg: "hsl(var(--warning-bg))",
        },
        danger: {
          DEFAULT: "hsl(var(--danger))",
          bg: "hsl(var(--danger-bg))",
        },
        info: {
          DEFAULT: "hsl(var(--info))",
          bg: "hsl(var(--info-bg))",
        },

        card: "hsl(var(--card))",
        "card-foreground": "hsl(var(--card-foreground))",
        cardForeground: "hsl(var(--card-foreground))",
        primaryForeground: "hsl(var(--primary-foreground))",
        secondary: "hsl(var(--secondary))",
        muted: "hsl(var(--muted))",
        "muted-foreground": "hsl(var(--muted-foreground))",
        mutedForeground: "hsl(var(--muted-foreground))",
        "accent-foreground": "hsl(var(--accent-foreground))",
        accentForeground: "hsl(var(--accent-foreground))",
      },
      borderRadius: {
        sm: "0.45rem",
        DEFAULT: "0.6rem",
        md: "0.7rem",
        lg: "0.95rem",
        xl: "1.2rem",
        "2xl": "1.45rem",
        "3xl": "1.8rem",
        btn: "0.5rem",
        card: "0.875rem",
        modal: "1.5rem",
        full: "9999px",
      },
      boxShadow: {
        soft: "0 1px 2px rgba(26,43,71,0.03)",
        medium: "0 4px 16px rgba(26,43,71,0.05)",
        large: "0 12px 32px rgba(26,43,71,0.06)",
        xl: "0 20px 48px rgba(26,43,71,0.08)",
        card: "0 1px 2px rgba(26,43,71,0.02)",
        "card-hover": "0 8px 24px rgba(26,43,71,0.06)",
        ring: "0 0 0 3px hsl(var(--ring) / 0.12)",
        glow: "0 2px 4px rgba(26,43,71,0.04)",
        "card-legacy": "0 1px 3px rgba(26,43,71,0.04)",
        lift: "0 12px 28px rgba(26,43,71,0.08)",
      },
      spacing: {
        xs: "0.25rem",
        sm: "0.5rem",
        md: "0.75rem",
        lg: "1rem",
        xl: "1.5rem",
        "2xl": "2rem",
        "3xl": "3rem",
        "4xl": "4rem",
      },
      fontSize: {
        "display-lg": ["2.45rem", { lineHeight: "2.95rem", fontWeight: "750", letterSpacing: "-0.028em" }],
        "display-md": ["2.02rem", { lineHeight: "2.45rem", fontWeight: "730", letterSpacing: "-0.026em" }],
        "display-sm": ["1.64rem", { lineHeight: "2.05rem", fontWeight: "700", letterSpacing: "-0.022em" }],

        "title-lg": ["1.3rem", { lineHeight: "1.82rem", fontWeight: "650", letterSpacing: "-0.016em" }],
        "title-md": ["1.15rem", { lineHeight: "1.66rem", fontWeight: "630", letterSpacing: "-0.011em" }],
        "title-sm": ["1.02rem", { lineHeight: "1.52rem", fontWeight: "620" }],

        "body-lg": ["1rem", { lineHeight: "1.56rem", fontWeight: "460" }],
        "body-md": ["0.89rem", { lineHeight: "1.42rem", fontWeight: "450" }],
        "body-sm": ["0.77rem", { lineHeight: "1.16rem", fontWeight: "430" }],

        "label-lg": ["0.88rem", { lineHeight: "1.28rem", fontWeight: "560" }],
        "label-md": ["0.76rem", { lineHeight: "1.16rem", fontWeight: "550" }],
        "label-sm": ["0.69rem", { lineHeight: "1.02rem", fontWeight: "550", letterSpacing: "0.04em" }],
      },
      animation: {
        "fade-in": "fade-in 220ms ease-out",
        "slide-up": "slide-up 280ms cubic-bezier(0.16, 1, 0.3, 1)",
        skeleton: "skeleton-pulse 1.6s cubic-bezier(0.4, 0, 0.6, 1) infinite",
      },
      keyframes: {
        "fade-in": {
          from: { opacity: "0" },
          to: { opacity: "1" },
        },
        "slide-up": {
          from: { transform: "translateY(10px)", opacity: "0" },
          to: { transform: "translateY(0)", opacity: "1" },
        },
        "skeleton-pulse": {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.48" },
        },
      },
      transitionDuration: {
        fast: "150ms",
        normal: "200ms",
        slow: "320ms",
      },
      transitionTimingFunction: {
        spring: "cubic-bezier(0.16, 1, 0.3, 1)",
      },
    },
  },
  plugins: [],
};

export default config;
