# frozen_string_literal: true

require "ruby_event_store/browser"
require "rails/engine"

module RailsEventStore
  class Browser < Rails::Engine
    endpoint RubyEventStore::Browser::Engine

    railtie_name "ruby_event_store_browser_app"
  end
end
