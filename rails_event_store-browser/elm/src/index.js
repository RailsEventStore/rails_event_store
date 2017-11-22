require("./style/style.scss");
const Elm = require("./Main.elm");
const app = Elm.Main.fullscreen({
  eventUrl: "/event.json",
  streamUrl: "/events.json",
  streamListUrl: "/streams.json",
  resVersion: "0.20.0"
});
