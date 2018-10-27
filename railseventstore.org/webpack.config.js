const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const path = require("path");

const config = {
  context: path.resolve(__dirname, "source"),
  output: {
    path: path.resolve(__dirname, ".tmp/dist"),
    filename: "javascripts/all.js"
  },
  entry: ["./stylesheets/styles.css"],
  module: {
    rules: []
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: "stylesheets/all.css"
    })
  ]
};

module.exports = (env, argv) => {
  if (argv.mode === "production") {
    config.module.rules.push({
      test: /\.css$/,
      use: [MiniCssExtractPlugin.loader, "css-loader", "postcss-loader"]
    });
  } else {
    config.module.rules.push({
      test: /\.css$/,
      use: ["style-loader", "css-loader", "postcss-loader"]
    });
  }

  return config;
};
