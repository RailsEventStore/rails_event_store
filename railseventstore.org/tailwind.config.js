module.exports = {
  content: [
    "./source/**/*.{html,md,erb}",
    "./layouts/**/*.erb",
    "./partials/**/*.erb",
    "./config.rb",
  ],
  plugins: [require("@tailwindcss/typography")],
};
