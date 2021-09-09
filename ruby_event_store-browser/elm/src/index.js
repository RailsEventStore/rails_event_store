require("./style/style.css");

var Browser = require("./Main.elm");

var settings = document.querySelector("meta[name='ruby-event-store-browser-settings']").getAttribute("content");
console.debug("settings", settings);
settings = JSON.parse(settings);
Browser.Elm.Main.init(settings);