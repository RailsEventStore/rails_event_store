# frozen_string_literal: true

require_relative "process_manager/version"
require_relative "process_manager/retry"

module RubyEventStore
  module ProcessManager
    module ProcessMethods
      def initialize(event_store, command_bus)
        @event_store = event_store
        @command_bus = command_bus
      end

      def call(event)
        @state = initial_state
        @id = fetch_id(event)
        build_state(event)
        act
      end

      private

      attr_reader :event_store, :command_bus, :id

      def build_state(event)
        with_retry do
          past_events = event_store.read.stream(stream_name).to_a
          last_stored = past_events.size - 1
          event_store.link(event.event_id, stream_name:, expected_version: last_stored)
          (past_events + [event]).each { |ev| @state = apply(ev) }
        end
      end

      def stream_name
        "#{self.class.name}$#{id}"
      end
    end

    module Subscriptions
      def self.extended(host_class)
        host_class.instance_variable_set(:@subscribed_events, [])
      end

      def subscribes_to(*events)
        @subscribed_events += events
      end

      attr_reader :subscribed_events
    end

    def self.with_state(&state_class_block)
      unless block_given?
        raise ArgumentError, "A block returning the state class is required."
      end

      Module.new do
        @state_definition_block = state_class_block

        define_method(:initial_state) do
          block = self.class.instance_variable_get(:@state_definition_block)
          raise "State definition block not found on #{self.class}" unless block

          state_class = block.call
          raise "State definition block did not return a Class" unless state_class.is_a?(Class)

          state_class.new
        end

        define_method(:state) do
          @state ||= initial_state
        end

        def self.included(host_class)
          host_class.instance_variable_set(:@state_definition_block, @state_definition_block)

          host_class.include(ProcessMethods)
          host_class.include(Retry)
          host_class.extend(Subscriptions)
        end
      end
    end
  end
end
