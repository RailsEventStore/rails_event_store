module.exports = {
  future: {
    // removeDeprecatedGapUtilities: true,
    // purgeLayersByDefault: true,
  },
  purge: [
    './source/**/*.html',
    './source/*.html',
    './source/**/*.md',
    './source/*.md',
    './source/**/*.erb',
    './source/*.erb',
  ],
  theme: {
    extend: {},
  },
  variants: {},
  plugins: [],
}
