# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HavePublished
      def initialize(mandatory_expected, *optional_expected, differ:, phraser:, failure_message_formatter: RSpec.default_formatter.have_published)
        @expected  = ExpectedCollection.new([mandatory_expected, *optional_expected])
        @phraser   = phraser
        @failure_message_formatter = failure_message_formatter.new(differ)
        @fetch_events = FetchEvents.new
      end

      def matches?(event_store)
        stream_names.all? do |stream_name|
          fetch_events.stream(stream_name) if stream_name
          fetch_events.in(event_store)
          @events = fetch_events.call
          @failed_on_stream = stream_name
          MatchEvents.new.call(expected, @events)
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

      def in_streams(*stream_names)
        @stream_names = stream_names.flatten
        self
      end

      def times
        self
      end
      alias :time :times

      def from(event_id)
        fetch_events.from(event_id)
        self
      end

      def once
        expected.once
        self
      end

      def failure_message
        failure_message_formatter.failure_message(expected, events, failed_on_stream)
      end

      def failure_message_when_negated
        failure_message_formatter.failure_message_when_negated(expected, events)
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

      attr_reader :phraser, :expected, :events, :failed_on_stream, :failure_message_formatter, :fetch_events
    end
  end
end
