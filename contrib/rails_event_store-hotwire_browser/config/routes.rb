# frozen_string_literal: true

stimulus_js = File.expand_path("../public/stimulus.js", __dir__)
browser_js = File.expand_path("../public/browser.js", __dir__)

RailsEventStore::HotwireBrowser::Engine.routes.draw do
  get "rails_event_store_hotwire_browser.css", to: "assets#stylesheet", as: :stylesheet
  get "stimulus.js",
      to: ->(_env) { [200, { "content-type" => "text/javascript" }, [File.binread(stimulus_js)]] },
      as: :stimulus,
      format: false
  get "browser.js",
      to: ->(_env) { [200, { "content-type" => "text/javascript" }, [File.binread(browser_js)]] },
      as: :browser_js,
      format: false

  root to: "streams#show", defaults: { id: RailsEventStore::HotwireBrowser::SERIALIZED_GLOBAL_STREAM_NAME }
  get "streams/:id", to: "streams#show", as: :stream, constraints: { id: /.+/ }, format: false
  get "events/:id", to: "events#show", as: :event, constraints: { id: /.+/ }, format: false
end
