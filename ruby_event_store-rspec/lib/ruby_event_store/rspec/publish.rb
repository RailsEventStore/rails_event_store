# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class Publish
      include ::RSpec::Matchers::Composable

      def initialize(*expected, failure_message_formatter:)
        @expected = ExpectedCollection.new(expected)
        @failure_message_formatter = failure_message_formatter
        @fetch_events = FetchEvents.new
        @start_for_stream = {}
      end

      def in(event_store)
        fetch_events.in(event_store)
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

      def exactly(count)
        expected.exactly(count)
        self
      end

      def once
        expected.once
        self
      end

      def times
        self
      end
      alias time times

      def strict
        expected.strict
        self
      end

      def matches?(event_proc)
        stream_names.each do |stream_name|
          fetch_events.stream(stream_name)
          @start_for_stream[stream_name] = fetch_events.call.last&.event_id
        end

        event_proc.call

        stream_names.all? do |stream_name|
          fetch_events.stream(stream_name)
          fetch_events.from(@start_for_stream.fetch(stream_name))
          @published_events = fetch_events.call.to_a
          @failed_on_stream = stream_name
          MatchEvents.new.call(expected, published_events)
        end
      rescue FetchEvents::MissingEventStore
        raise "You have to set the event store instance with `in`, e.g. `expect { ... }.to publish(an_event(MyEvent)).in(event_store)`"
      end

      def failure_message
        failure_message_formatter.failure_message(expected, published_events, failed_on_stream)
      end

      def failure_message_when_negated
        failure_message_formatter.failure_message_when_negated(expected, published_events, fetch_events.stream_name)
      end

      def description
        "publish events"
      end

      def supports_block_expectations?
        true
      end

      private

      def stream_names
        @stream_names || [nil]
      end

      attr_reader :fetch_events, :expected, :failure_message_formatter, :published_events, :failed_on_stream
    end
  end
end
