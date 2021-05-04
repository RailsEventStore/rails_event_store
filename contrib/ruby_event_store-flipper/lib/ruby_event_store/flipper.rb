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

      class ToggleEnabledForActor < RubyEventStore::Event
      end

      class ToggleDisabledForActor < RubyEventStore::Event
      end

      class ToggleEnabledForGroup < RubyEventStore::Event
      end

      class ToggleDisabledForGroup < RubyEventStore::Event
      end

      class ToggleEnabledForPercentageOfActors < RubyEventStore::Event
      end

      class ToggleDisabledForPercentageOfActors < RubyEventStore::Event
      end

      class ToggleEnabledForPercentageOfTime < RubyEventStore::Event
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
          gate_name = event.payload.fetch(:gate_name)
          thing = event.payload.fetch(:thing)
          if gate_name.eql?(:boolean)
            event_store.publish(Events::ToggleGloballyEnabled.new(data: {
              feature_name: feature_name
            }), stream_name: stream_name(feature_name))
          elsif gate_name.eql?(:actor)
            event_store.publish(Events::ToggleEnabledForActor.new(data: {
              feature_name: feature_name,
              actor: thing.value,
            }), stream_name: stream_name(feature_name))
          elsif gate_name.eql?(:group)
            event_store.publish(Events::ToggleEnabledForGroup.new(data: {
              feature_name: feature_name,
              group: thing.value.to_s,
            }), stream_name: stream_name(feature_name))
          elsif gate_name.eql?(:percentage_of_actors)
            event_store.publish(Events::ToggleEnabledForPercentageOfActors.new(data: {
              feature_name: feature_name,
              percentage: thing.value,
            }), stream_name: stream_name(feature_name))
          else
            event_store.publish(Events::ToggleEnabledForPercentageOfTime.new(data: {
              feature_name: feature_name,
              percentage: thing.value,
            }), stream_name: stream_name(feature_name))
          end
        when :disable
          gate_name = event.payload.fetch(:gate_name)
          thing = event.payload.fetch(:thing)
          if gate_name.eql?(:boolean)
            event_store.publish(Events::ToggleGloballyDisabled.new(data: {
              feature_name: feature_name
            }), stream_name: stream_name(feature_name))
          elsif gate_name.eql?(:actor)
            event_store.publish(Events::ToggleDisabledForActor.new(data: {
              feature_name: feature_name,
              actor: thing.value,
            }), stream_name: stream_name(feature_name))
          elsif gate_name.eql?(:group)
            event_store.publish(Events::ToggleDisabledForGroup.new(data: {
              feature_name: feature_name,
              group: thing.value.to_s,
            }), stream_name: stream_name(feature_name))
          else
            event_store.publish(Events::ToggleDisabledForPercentageOfActors.new(data: {
              feature_name: feature_name,
            }), stream_name: stream_name(feature_name))
          end
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
