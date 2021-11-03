# frozen_string_literal: true

require_relative "flipper/version"
require "ruby_event_store"

module RubyEventStore
  module Flipper
    DEFAULT_STREAM_PATTERN = ->(feature_name) { "FeatureToggle$#{feature_name}" }

    def self.enable(event_store, instrumenter: ActiveSupport::Notifications, stream_pattern: DEFAULT_STREAM_PATTERN)
      instrumenter.subscribe("feature_operation.flipper", NotificationHandler.new(event_store, stream_pattern))
    end

    class NotificationHandler
      def initialize(event_store, stream_pattern)
        @event_store = event_store
        @stream_pattern = stream_pattern
      end

      def call(_name, _start, _finish, _id, payload)
        feature_name = payload.fetch(:feature_name).to_s
        operation = payload.fetch(:operation)
        common_payload = { feature_name: feature_name }
        event_store.publish(build_domain_event(common_payload, operation, payload), stream_name: stream_pattern.(feature_name))
      end

      private

      attr_reader :event_store, :stream_pattern

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
    end
  end
end
