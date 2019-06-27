# frozen_string_literal: true

require 'ruby_event_store/browser/app'

module RailsEventStore
  Browser = RubyEventStore::Browser::App.for(event_store_locator: -> { Rails.configuration.event_store })
end