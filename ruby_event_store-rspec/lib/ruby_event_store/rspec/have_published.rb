# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HavePublished
      def initialize(*expected, phraser:, failure_message_formatter:)
        @expected = ExpectedCollection.new(expected)
        @phraser = phraser
        @failure_message_formatter = failure_message_formatter
        @fetch_events = FetchEvents.new
      end

      def matches?(event_store)
        stream_names.all? do |stream_name|
          fetch_events.stream(stream_name)
          fetch_events.in(event_store)
          @published_events = fetch_events.call.to_a
          @failed_on_stream = stream_name
          MatchEvents.new.call(expected, published_events)
        end
      end

      def exactly(count)
        expected.exactly(count)
        self
      end

      def in_stream(stream_name)
        @stream_names = [stream_name]
        self
      end

      def in_streams(stream_names)
        @stream_names = Array(stream_names)
        self
      end

      def times
        self
      end
      alias time times

      def from(event_id)
        fetch_events.from(event_id)
        self
      end

      def once
        expected.once
        self
      end

      def failure_message
        failure_message_formatter.failure_message(expected, published_events, failed_on_stream)
      end

      def failure_message_when_negated
        failure_message_formatter.failure_message_when_negated(expected, published_events, failed_on_stream)
      end

      def description
        "have published events that have to (#{phraser.(expected.events)})"
      end

      def strict
        expected.strict
        self
      end

      private

      def stream_names
        @stream_names || [nil]
      end

      attr_reader :phraser, :expected, :published_events, :failed_on_stream, :failure_message_formatter, :fetch_events
    end
  end
end
