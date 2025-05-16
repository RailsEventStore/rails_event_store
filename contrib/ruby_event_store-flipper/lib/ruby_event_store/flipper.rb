# frozen_string_literal: true

require_relative "flipper/version"
require "ruby_event_store"
require_relative "flipper/events"

module RubyEventStore
  module Flipper
    DEFAULT_STREAM_PATTERN = ->(feature_name) { "FeatureToggle$#{feature_name}" }

    def self.enable(
      event_store,
      instrumenter: ActiveSupport::Notifications,
      stream_pattern: DEFAULT_STREAM_PATTERN,
      custom_events: nil
    )
      instrumenter.subscribe(
        "feature_operation.flipper",
        NotificationHandler.new(event_store, stream_pattern, custom_events),
      )
    end

    class NotificationHandler
      def initialize(event_store, stream_pattern, custom_events)
        @event_store = event_store
        @stream_pattern = stream_pattern
        @custom_events = {
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
        }.merge(custom_events || {})
      end

      def call(_name, _start, _finish, _id, payload)
        feature_name = payload.fetch(:feature_name).to_s
        operation = payload.fetch(:operation)
        common_payload = { feature_name: feature_name }
        if (domain_event = build_domain_event(common_payload, operation, payload))
          event_store.publish(domain_event, stream_name: stream_pattern.(feature_name))
        end
      end

      private

      attr_reader :event_store, :stream_pattern, :custom_events

      def build_domain_event(common_payload, operation, payload)
        case operation
        when :add
          event_klass("ToggleAdded").new(data: common_payload)
        when :remove
          event_klass("ToggleRemoved").new(data: common_payload)
        when :enable
          gate_name = payload.fetch(:gate_name)
          thing = payload.fetch(:thing)
          case gate_name
          when :boolean
            event_klass("ToggleGloballyEnabled").new(data: common_payload)
          when :actor
            event_klass("ToggleEnabledForActor").new(data: common_payload.merge(actor: thing.value))
          when :group
            event_klass("ToggleEnabledForGroup").new(data: common_payload.merge(group: thing.value.to_s))
          when :percentage_of_actors
            event_klass("ToggleEnabledForPercentageOfActors").new(data: common_payload.merge(percentage: thing.value))
          when :percentage_of_time
            event_klass("ToggleEnabledForPercentageOfTime").new(data: common_payload.merge(percentage: thing.value))
          end
        when :disable
          gate_name = payload.fetch(:gate_name)
          thing = payload.fetch(:thing)
          case gate_name
          when :boolean
            event_klass("ToggleGloballyDisabled").new(data: common_payload)
          when :actor
            event_klass("ToggleDisabledForActor").new(data: common_payload.merge(actor: thing.value))
          when :group
            event_klass("ToggleDisabledForGroup").new(data: common_payload.merge(group: thing.value.to_s))
          when :percentage_of_actors
            event_klass("ToggleDisabledForPercentageOfActors").new(data: common_payload)
          when :percentage_of_time
            event_klass("ToggleDisabledForPercentageOfTime").new(data: common_payload)
          end
        end
      end

      def event_klass(event_name)
        custom_events.fetch(event_name)
      end
    end
  end
end
