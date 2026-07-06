# frozen_string_literal: true

stimulus_js = File.expand_path("../public/stimulus.js", __dir__)
browser_js = File.expand_path("../public/browser.js", __dir__)

RubyEventStore::Browser::Engine.routes.draw do
  get "ruby_event_store_browser.css", to: "assets#stylesheet", as: :stylesheet
  get "stimulus",
      to: ->(_env) { [200, { "content-type" => "text/javascript" }, [File.binread(stimulus_js)]] },
      as: :stimulus
  get "browser.js",
      to: ->(_env) { [200, { "content-type" => "text/javascript" }, [File.binread(browser_js)]] },
      as: :browser_js,
      format: false

  root to: "streams#show", defaults: { id: RubyEventStore::Browser::SERIALIZED_GLOBAL_STREAM_NAME }
  get "streams/:id", to: "streams#show", as: :stream, constraints: { id: /.+/ }, format: false
  get "events/:id", to: "events#show", as: :event, constraints: { id: /.+/ }, format: false
end
