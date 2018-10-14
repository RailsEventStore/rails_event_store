const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const path = require("path");

module.exports = {
  context: path.resolve(__dirname, "source"),
  output: {
    path: path.resolve(__dirname, ".tmp/dist"),
    filename: "javascripts/all.js"
  },
  entry: [
    "./stylesheets/_open-color.css",
    "./stylesheets/_solarized.css",
    "./stylesheets/_site.css",
    "./stylesheets/_site_navigation.css"
  ],
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, "css-loader", "postcss-loader"]
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: "stylesheets/all.css"
    })
  ]
};
