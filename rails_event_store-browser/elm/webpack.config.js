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
const path = require("path");

module.exports = createConfig([
  entryPoint("./src/index.js"),
  setOutput("../public/rails_event_store_browser.js"),
  elm(),
  sass(),
  defineConstants({
    "process.env.NODE_ENV": process.env.NODE_ENV
  }),
  env("development", [
    devServer({
      contentBase: "./src",
      before: app => {
        app.get("/streams", (req, res) =>
          res.sendFile(path.resolve("./src/streams.json"))
        );
        app.get("/streams/*", (req, res) =>
          res.sendFile(path.resolve("./src/events.json"))
        );
        app.get("/events/*", (req, res) =>
          res.sendFile(path.resolve("./src/event.json"))
        );
      }
    }),
    addPlugins([
      new HTMLWebpackPlugin({
        template: "src/index.html",
        inject: false
      })
    ])
  ])
]);
