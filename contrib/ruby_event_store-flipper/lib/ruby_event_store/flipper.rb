# frozen_string_literal: true

require_relative "flipper/version"
require "ruby_event_store"

module RubyEventStore
  module Flipper
    def self.enable(event_store)
      ActiveSupport::Notifications.subscribe("feature_operation.flipper", NotificationHandler.new(event_store))
    end

    module Events
      class ToggleAdded < RubyEventStore::Event
      end

      class ToggleRemoved < RubyEventStore::Event
      end

      class ToggleGloballyEnabled < RubyEventStore::Event
      end

      class ToggleGloballyDisabled < RubyEventStore::Event
      end
    end

    class NotificationHandler
      def initialize(event_store)
        @event_store = event_store
      end

      def call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        feature_name = event.payload.fetch(:feature_name).to_s
        operation = event.payload.fetch(:operation)
        case operation
        when :add
          event_store.publish(Events::ToggleAdded.new(data: {
            feature_name: feature_name,
          }), stream_name: stream_name(feature_name))
        when :remove
          event_store.publish(Events::ToggleRemoved.new(data: {
            feature_name: feature_name,
          }), stream_name: stream_name(feature_name))
        when :enable
          event_store.publish(Events::ToggleGloballyEnabled.new(data: {
            feature_name: feature_name
          }), stream_name: stream_name(feature_name))
        when :disable
          event_store.publish(Events::ToggleGloballyDisabled.new(data: {
            feature_name: feature_name
          }), stream_name: stream_name(feature_name))
        end
      end

      private

      attr_reader :event_store

      def stream_name(feature_name)
        "FeatureToggle$#{feature_name}"
      end
    end
  end
end
