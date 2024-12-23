const { fontFamily } = require("tailwindcss/defaultTheme");

/** @type {import('tailwindcss').Config} */
module.exports = {
 
  darkMode: ["class", '[data-theme="dark"]'],
  content: ["./src/**/*.{js,jsx,tsx,html}", "./docs/**/*.{md,mdx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Inter"', ...fontFamily.sans],
        jakarta: ['"Plus Jakarta Sans"', ...fontFamily.sans],
        mono: ['"Fira Code"', ...fontFamily.mono],
      },
      borderRadius: {
        sm: "4px",
      },
      colors: {
        res: "#BB4539",
      },
    },
  },
  safelist: ["mt-8"],
  plugins: [
    require('@tailwindcss/typography'),
  ],
};
