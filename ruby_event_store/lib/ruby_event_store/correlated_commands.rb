# frozen_string_literal: true

module RubyEventStore
  class CorrelatedCommands

    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    class MiniEvent < Struct.new(:correlation_id, :message_id)
    end

    def call(command)
      correlation_id = event_store.metadata[:correlation_id]
      causation_id   = event_store.metadata[:causation_id]

      if correlation_id && causation_id
        command.correlate_with(MiniEvent.new(
          correlation_id,
          causation_id,
        )) if command.respond_to?(:correlate_with)
        event_store.with_metadata(
          causation_id: command.message_id,
        ) do
          command_bus.call(command)
        end
      else
        event_store.with_metadata(
          correlation_id: command.message_id,
          causation_id: command.message_id,
        ) do
          command_bus.call(command)
        end
      end
    end

    private

    attr_reader :event_store, :command_bus
  end
end
