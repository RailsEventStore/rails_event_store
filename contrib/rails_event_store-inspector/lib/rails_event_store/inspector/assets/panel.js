(function () {
  if (window.__resInspector) return;
  window.__resInspector = true;

  var KEY = "res-inspector-open";

  function container() {
    return document.getElementById("res-inspector");
  }

  function isOpen() {
    return localStorage.getItem(KEY) === "1";
  }

  function setCount(value) {
    var badge = document.getElementById("res-inspector-count");
    if (badge && value !== null) badge.textContent = value;
  }

  function load() {
    var root = container();
    var panel = document.getElementById("res-inspector-panel");
    if (!root || !panel) return;
    var url = root.dataset.panelPath + (isOpen() ? "" : "?count=1");

    fetch(url, { credentials: "same-origin" })
      .then(function (response) {
        if (!response.ok) return null;
        var count = response.headers.get(root.dataset.countHeader);
        return response.text().then(function (body) {
          return { body: body, count: count };
        });
      })
      .then(function (result) {
        if (!result) return;
        setCount(result.count);
        if (!isOpen()) return;
        panel.innerHTML = result.body;
        panel.scrollTop = panel.scrollHeight;
      });
  }

  function apply() {
    document.documentElement.dataset.resInspector = isOpen() ? "open" : "closed";
    load();
  }

  document.addEventListener("click", function (event) {
    if (event.target.closest("#res-inspector-toggle")) {
      localStorage.setItem(KEY, isOpen() ? "0" : "1");
    } else if (event.target.closest("#res-inspector-close")) {
      localStorage.setItem(KEY, "0");
    } else {
      return;
    }
    apply();
  });

  ["turbo:load", "turbo:render", "DOMContentLoaded"].forEach(function (name) {
    document.addEventListener(name, apply);
  });
  document.addEventListener("turbo:before-stream-render", function () {
    setTimeout(load, 0);
  });

  apply();
})();
