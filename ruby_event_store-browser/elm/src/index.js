import "./style/style.css";
import { Elm } from "./Main.elm";

var settings = document
  .querySelector("meta[name='ruby-event-store-browser-settings']")
  .getAttribute("content");

Elm.Main.init({ flags: JSON.parse(settings) });
