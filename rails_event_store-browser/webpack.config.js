const webpack = require("webpack");
const HTMLWebpackPlugin = require("html-webpack-plugin");
const {
  createConfig,
  devServer,
  addPlugins,
  defineConstants,
  entryPoint,
  setOutput,
  env,
  sass
} = require("webpack-blocks");
const elm = require("@webpack-blocks/elm");

module.exports = createConfig([
  entryPoint("./src/index.js"),
  setOutput("./build/bundle.js"),
  elm(),
  sass(),
  addPlugins([
    new HTMLWebpackPlugin({
      title: "Browser"
    })
  ]),
  defineConstants({
    "process.env.NODE_ENV": process.env.NODE_ENV
  }),
  env("development", [devServer({ contentBase: "./src" })])
]);
