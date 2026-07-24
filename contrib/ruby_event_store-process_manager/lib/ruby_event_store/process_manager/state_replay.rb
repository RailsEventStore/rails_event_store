# frozen_string_literal: true

module RubyEventStore
  module ProcessManager
    class StateReplay
      Step = Struct.new(:event, :state, keyword_init: true)
      Result = Struct.new(:steps, :current_state, keyword_init: true)

      def initialize(event_store:)
        @event_store = event_store
      end

      def call(process_class, stream_name)
        process = process_class.new(@event_store, nil)
        events = @event_store.read.stream(stream_name).to_a
        states = process.replay(events)
        Result.new(
          steps: events.zip(states).map { |event, state| Step.new(event: event, state: state) },
          current_state: process.state,
        )
      end
    end
  end
end
