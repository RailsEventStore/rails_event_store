module.exports = {
  purge: [
    './src/style.css',
    './src/**/*.elm'
  ],
  theme: {
    extend: {}
  },
  variants: {
    extend: {
      opacity: ["disabled"],
      cursor:  ["disabled"]
    }
  },
  plugins: []
}
