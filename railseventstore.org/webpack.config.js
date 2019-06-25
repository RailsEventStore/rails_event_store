const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const path = require("path");

const config = {
  context: path.resolve(__dirname, "source"),
  output: {
    path: path.resolve(__dirname, ".tmp/dist"),
    filename: "javascripts/all.js"
  },
  entry: ["./stylesheets/styles.css", "./stats.js"],
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
  config.module.rules.push(
    {test: /\.js$/, exclude: /node_modules/, loader: "babel-loader"}
  );

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
