# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class FetchEvents
      MissingEventStore = Class.new(StandardError)

      def from(event_id)
        @start = event_id
      end

      def stream(stream_name)
        @stream_name = stream_name
      end

      def in(event_store)
        @event_store = event_store
      end

      def call
        raise MissingEventStore if event_store.nil?
        events = event_store.read
        events = events.stream(stream_name) if stream_name
        events = events.from(start) if start
        events
      end

      attr_reader :start, :stream_name, :event_store
    end
  end
end
