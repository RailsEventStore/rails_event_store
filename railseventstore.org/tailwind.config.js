module.exports = {
  content: [
    "./source/**/*.{html,md,erb}",
    "./layouts/**/*.erb",
    "./partials/**/*.erb",
    "./config.rb",
  ],
  theme: {
    extend: {
      maxWidth: {
        '8xl': '88rem',
      },
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
