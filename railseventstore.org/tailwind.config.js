const { fontFamily } = require("tailwindcss/defaultTheme");

/** @type {import('tailwindcss').Config} */
module.exports = {
 
  darkMode: ["selector", '[data-theme="dark"]'],
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
  safelist: ["mt-8", "w-20", "-translate-y-[3px]", "max-w-4xl"],
  plugins: [
    require('@tailwindcss/typography'),
  ],
};
