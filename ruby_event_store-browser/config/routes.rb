# frozen_string_literal: true

RubyEventStore::Browser::Engine.routes.draw do
  get "ruby_event_store_browser.css", to: "assets#stylesheet", as: :stylesheet
end
