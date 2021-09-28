const elmPlugin = require("esbuild-plugin-elm");
const cssPlugin = require("@deanc/esbuild-plugin-postcss");
const isProduction = process.env.NODE_ENV == "production";

require("esbuild")
  .build({
    entryPoints: ["src/index.js"],
    bundle: true,
    minify: isProduction,
    outfile: "../public/ruby_event_store_browser.js",
    plugins: [
      cssPlugin({
        plugins: [require("tailwindcss"), require("autoprefixer")],
      }),
      elmPlugin({ debug: !isProduction }),
    ],
  })
  .catch(() => process.exit(1));
