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

      class ToggleDisabledForPercentageOfTime < RubyEventStore::Event
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
        common_payload = { feature_name: feature_name }
        event_store.publish(build_domain_event(common_payload, operation, event.payload), stream_name: stream_name(feature_name))
      end

      private

      attr_reader :event_store

      def build_domain_event(common_payload, operation, payload)
        case operation
        when :add
          Events::ToggleAdded.new(data: common_payload)
        when :remove
          Events::ToggleRemoved.new(data: common_payload)
        when :enable
          gate_name = payload.fetch(:gate_name)
          thing = payload.fetch(:thing)
          case gate_name
          when :boolean
            Events::ToggleGloballyEnabled.new(data: common_payload)
          when :actor
            Events::ToggleEnabledForActor.new(data: common_payload.merge(
              actor: thing.value,
            ))
          when :group
            Events::ToggleEnabledForGroup.new(data: common_payload.merge(
              group: thing.value.to_s,
            ))
          when :percentage_of_actors
            Events::ToggleEnabledForPercentageOfActors.new(data: common_payload.merge(
              percentage: thing.value,
            ))
          when :percentage_of_time
            Events::ToggleEnabledForPercentageOfTime.new(data: common_payload.merge(
              percentage: thing.value,
            ))
          end
        when :disable
          gate_name = payload.fetch(:gate_name)
          thing = payload.fetch(:thing)
          case gate_name
          when :boolean
            Events::ToggleGloballyDisabled.new(data: common_payload)
          when :actor
            Events::ToggleDisabledForActor.new(data: common_payload.merge(
              actor: thing.value,
            ))
          when :group
            Events::ToggleDisabledForGroup.new(data: common_payload.merge(
              group: thing.value.to_s,
            ))
          when :percentage_of_actors
            Events::ToggleDisabledForPercentageOfActors.new(data: common_payload)
          when :percentage_of_time
            Events::ToggleDisabledForPercentageOfTime.new(data: common_payload)
          end
        end
      end

      def stream_name(feature_name)
        "FeatureToggle$#{feature_name}"
      end
    end
  end
end
