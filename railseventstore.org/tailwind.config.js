module.exports = {
  content: [
    "./source/**/*.html",
    "./source/*.html",
    "./source/**/*.md",
    "./source/*.md",
    "./source/**/*.erb",
    "./source/*.erb",
    "./config.rb",
  ],
  plugins: [require("@tailwindcss/typography")],
};
