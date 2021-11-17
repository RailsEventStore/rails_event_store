# frozen_string_literal: true

require_relative "flipper/version"
require "ruby_event_store"

module RubyEventStore
  module Flipper
    DEFAULT_STREAM_PATTERN = ->(feature_name) { "FeatureToggle$#{feature_name}" }

    def self.enable(event_store, instrumenter: ActiveSupport::Notifications, stream_pattern: DEFAULT_STREAM_PATTERN, custom_events: nil)
      load File.expand_path("../../generators/ruby_event_store/flipper/templates/events.rb", __FILE__) unless custom_events
      instrumenter.subscribe("feature_operation.flipper", NotificationHandler.new(event_store, stream_pattern, custom_events))
    end

    class NotificationHandler
      def initialize(event_store, stream_pattern, custom_events)
        @event_store = event_store
        @stream_pattern = stream_pattern
        @custom_events = custom_events || {
          "ToggleAdded" => Events::ToggleAdded,
          "ToggleRemoved" => Events::ToggleRemoved,
          "ToggleGloballyEnabled" => Events::ToggleGloballyEnabled,
          "ToggleEnabledForActor" => Events::ToggleEnabledForActor,
          "ToggleEnabledForGroup" => Events::ToggleEnabledForGroup,
          "ToggleEnabledForPercentageOfActors" => Events::ToggleEnabledForPercentageOfActors,
          "ToggleEnabledForPercentageOfTime" => Events::ToggleEnabledForPercentageOfTime,
          "ToggleGloballyDisabled" => Events::ToggleGloballyDisabled,
          "ToggleDisabledForActor" => Events::ToggleDisabledForActor,
          "ToggleDisabledForGroup" => Events::ToggleDisabledForGroup,
          "ToggleDisabledForPercentageOfActors" => Events::ToggleDisabledForPercentageOfActors,
          "ToggleDisabledForPercentageOfTime" => Events::ToggleDisabledForPercentageOfTime,
        }
      end

      def call(_name, _start, _finish, _id, payload)
        feature_name = payload.fetch(:feature_name).to_s
        operation = payload.fetch(:operation)
        common_payload = { feature_name: feature_name }
        event_store.publish(build_domain_event(common_payload, operation, payload), stream_name: stream_pattern.(feature_name))
      end

      private

      attr_reader :event_store, :stream_pattern, :custom_events

      def build_domain_event(common_payload, operation, payload)
        case operation
        when :add
          custom_events.fetch("ToggleAdded").new(data: common_payload)
        when :remove
          custom_events.fetch("ToggleRemoved").new(data: common_payload)
        when :enable
          gate_name = payload.fetch(:gate_name)
          thing = payload.fetch(:thing)
          case gate_name
          when :boolean
            custom_events.fetch("ToggleGloballyEnabled").new(data: common_payload)
          when :actor
            custom_events.fetch("ToggleEnabledForActor").new(data: common_payload.merge(
              actor: thing.value,
            ))
          when :group
            custom_events.fetch("ToggleEnabledForGroup").new(data: common_payload.merge(
              group: thing.value.to_s,
            ))
          when :percentage_of_actors
            custom_events.fetch("ToggleEnabledForPercentageOfActors").new(data: common_payload.merge(
              percentage: thing.value,
            ))
          when :percentage_of_time
            custom_events.fetch("ToggleEnabledForPercentageOfTime").new(data: common_payload.merge(
              percentage: thing.value,
            ))
          end
        when :disable
          gate_name = payload.fetch(:gate_name)
          thing = payload.fetch(:thing)
          case gate_name
          when :boolean
            custom_events.fetch("ToggleGloballyDisabled").new(data: common_payload)
          when :actor
            custom_events.fetch("ToggleDisabledForActor").new(data: common_payload.merge(
              actor: thing.value,
            ))
          when :group
            custom_events.fetch("ToggleDisabledForGroup").new(data: common_payload.merge(
              group: thing.value.to_s,
            ))
          when :percentage_of_actors
            custom_events.fetch("ToggleDisabledForPercentageOfActors").new(data: common_payload)
          when :percentage_of_time
            custom_events.fetch("ToggleDisabledForPercentageOfTime").new(data: common_payload)
          end
        end
      end
    end
  end
end
