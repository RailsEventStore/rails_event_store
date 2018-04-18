module RubyEventStore
  module ROM
    class EventRepository
      ACCEPTABLE_UUID_FORMAT = /^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$/

      def initialize(rom: ROM.env)
        @rom = rom
        @events = Repositories::Events.new(rom)
        @stream_entries = Repositories::StreamEntries.new(rom)
      end

      def append_to_stream(events, stream, expected_version)
        events = normalize_to_array(events)
        event_ids = events.map(&:event_id)

        @rom.gateways[:default].transaction(savepoint: true) do
          @events.create(events)
          @stream_entries.create(event_ids, stream, expected_version, global_stream: true)
        end

        self
      rescue ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation => ex
        raise_error(ex)
      end

      def link_to_stream(event_ids, stream, expected_version)
        @stream_entries.create(normalize_to_array(event_ids), stream, expected_version)

        self
      rescue ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation => ex
        raise_error(ex)
      end

      def delete_stream(stream)
        @stream_entries.delete(stream)
      end

      def has_event?(event_id)
        return false unless event_id =~ ACCEPTABLE_UUID_FORMAT
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
        @events.by_id(event_id)
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
