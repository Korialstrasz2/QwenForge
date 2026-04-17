import type { Config } from "tailwindcss";

export default {
  darkMode: ["class"],
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        panel: "#11161f",
        chrome: "#0b0f16",
        accent: "#7c9cff"
      }
    }
  },
  plugins: []
} satisfies Config;
