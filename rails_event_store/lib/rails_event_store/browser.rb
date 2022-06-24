# frozen_string_literal: true

require "ruby_event_store/browser/app"
require "rails/engine"

module RailsEventStore
  class Browser < Rails::Engine
    endpoint RubyEventStore::Browser::App.for(event_store_locator: -> { Rails.configuration.event_store })

    railtie_name "ruby_event_store_browser_app"
  end
end
