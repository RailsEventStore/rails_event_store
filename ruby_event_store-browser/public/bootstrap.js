const flags = JSON.parse(document.querySelector("meta[name='ruby-event-store-browser-settings']").getAttribute("content"));
flags.platform = navigator.platform;
const app = Elm.Main.init({flags});

app.ports.copyToClipboard.subscribe(function (message) {
  navigator.clipboard.writeText(message);
});

app.ports.toggleDialog.subscribe(function (id) {
  const dialog = document.querySelector(`#${id}`);
  dialog.open ? dialog.close() : dialog.showModal();
});

app.ports.closeSearch.subscribe(function (id) {
  document.querySelector(`#${id}`).close();
});

window.addEventListener("keydown", function (event) {
  if (event.key === "k" && (event.ctrlKey || event.metaKey)) {
    app.ports.requestSearch.send(null);
    event.preventDefault();
  }

  if (event.key === "Escape") {
    app.ports.requestSearchClose.send(null);
    event.preventDefault();
  }
});

app.ports.toggleBookmark.subscribe(function (id) {
  const bookmarks = JSON.parse(localStorage.getItem("bookmarks")) || [];
  if (bookmarks.indexOf(id) >= 0) {
    bookmarks.splice(bookmarks.indexOf(id), 1);
  } else {
    bookmarks.push(id);
  }
  console.log(bookmarks);
  localStorage.setItem("bookmarks", JSON.stringify(bookmarks));
});
