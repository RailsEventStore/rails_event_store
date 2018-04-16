module RubyEventStore
  module ROM
    class EventRepository
      def initialize(rom: ROM.env)
        @events        = Repositories::Events.new(rom)
        @event_streams = Repositories::EventStreams.new(rom)
      end

      def append_to_stream(events, stream, expected_version)
        @events.create(
          normalize_to_array(events),
          stream: stream,
          expected_version: ExpectedVersion.new(expected_version)
        )

        self
      rescue ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation => ex
        raise_error(ex)
      end

      def link_to_stream(event_ids, stream, expected_version)
        @events.link(normalize_to_array(event_ids), stream, ExpectedVersion.new(expected_version))

        self
      rescue ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation => ex
        raise_error(ex)
      end

      def delete_stream(stream)
        @event_streams.delete(stream)
      end

      def has_event?(event_id)
        @events.exist?(event_id)
      end

      def last_stream_event(stream)
        @events.read(:backward, stream, limit: 1).first
      end

      def read_events_forward(stream, after_event_id, count)
        @events.read(:forward, stream, from: after_event_id, limit: count)
      end

      def read_events_backward(stream, before_event_id, count)
        @events.read(:backward, stream, from: before_event_id, limit: count)
      end

      def read_stream_events_forward(stream)
        @events.read(:forward, stream)
      end

      def read_stream_events_backward(stream)
        @events.read(:backward, stream)
      end

      def read_all_streams_forward(after_event_id, count)
        read_events_forward(RubyEventStore::Stream.new(GLOBAL_STREAM), after_event_id, count)
      end

      def read_all_streams_backward(before_event_id, count)
        read_events_backward(RubyEventStore::Stream.new(GLOBAL_STREAM), before_event_id, count)
      end

      def read_event(event_id)
        @events.fetch(event_id)
      rescue ::ROM::TupleCountMismatchError
        raise EventNotFound.new(event_id)
      end

      private

      def raise_error(ex)
        raise EventDuplicatedInStream if detect_index_violated(ex.message)
        raise WrongExpectedEventVersion
      end

      def detect_index_violated(message)
        IndexViolationDetector.new.detect(message)
      end

      def normalize_to_array(events)
        return events if events.is_a?(Enumerable)
        [events]
      end
    end
  end
end
