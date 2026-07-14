# frozen_string_literal: true

module RailsEventStore
  module HotwireBrowser
    module IntegrationHelpers
      class << self
        def included(base)
          base.include(with)
        end

        def with(app: ->(itself) { itself }, host: "www.example.com")
          Module.new do
            define_method :default_app do
              TestApplication.config.event_store = event_store
              TestApplication
            end

            define_method :web_client do
              @web_client ||= WebClient.new(app[default_app], host)
            end

            define_method :event_store do
              @event_store ||=
                RubyEventStore::Client.new.tap do |event_store|
                  event_store.subscribe_to_all_events(RubyEventStore::LinkByCorrelationId.new(event_store: event_store))
                  event_store.subscribe_to_all_events(RubyEventStore::LinkByCausationId.new(event_store: event_store))
                  event_store.subscribe_to_all_events(RubyEventStore::LinkByEventType.new(event_store: event_store))
                end
            end
          end
        end
      end
    end
  end
end
