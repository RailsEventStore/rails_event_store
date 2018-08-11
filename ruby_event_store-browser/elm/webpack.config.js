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
  setOutput("../public/ruby_event_store_browser.js"),
  elm(),
  sass(),
  defineConstants({
    "process.env.NODE_ENV": process.env.NODE_ENV
  }),
  addPlugins([
    new webpack.NoEmitOnErrorsPlugin()
  ]),
  env("development", [
    devServer({
      contentBase: "./src",
      before: app => {
        app.get("/streams/head/backward/20", (req, res) =>
          res.sendFile(path.resolve("./src/mocks/streams_0.json"))
        );
        app.get("/streams/head/forward/20", (req, res) =>
          res.sendFile(path.resolve("./src/mocks/streams_1.json"))
        );
        app.get("/streams/Caterer_96/forward/20", (req, res) =>
          res.sendFile(path.resolve("./src/mocks/streams_0.json"))
        );
        app.get("/streams/Caterer_8/backward/20", (req, res) =>
          res.sendFile(path.resolve("./src/mocks/streams_1.json"))
        );
        app.get("/streams", (req, res) =>
          res.sendFile(path.resolve("./src/mocks/streams_0.json"))
        );
        app.get("/events/*", (req, res) =>
          res.sendFile(path.resolve("./src/mocks/event.json"))
        );
        app.get("/streams/*/head/backward/20", (req, res) =>
          res.sendFile(path.resolve("./src/mocks/events_0.json"))
        );
        app.get(
          "/streams/*/5cc3a5e1-b8ef-43fc-a5d9-63c7e75fb4ab/forward/20",
          (req, res) => res.sendFile(path.resolve("./src/mocks/events_0.json"))
        );
        app.get("/streams/*/head/forward/20", (req, res) =>
          res.sendFile(path.resolve("./src/mocks/events_1.json"))
        );
        app.get(
          "/streams/*/d9d643da-5de2-404d-9d9a-b0abee4aa7fe/backward/20",
          (req, res) => res.sendFile(path.resolve("./src/mocks/events_1.json"))
        );
        app.get("/streams/*", (req, res) =>
          res.sendFile(path.resolve("./src/mocks/events_0.json"))
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
