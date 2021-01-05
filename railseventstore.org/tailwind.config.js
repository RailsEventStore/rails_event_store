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
    './config.rb'
  ],
  theme: {
    extend: {},
  },
  variants: {},
  plugins: [],
}
