module RubyEventStoreRomSql
  class EventRepository
    def initialize(rom: RubyEventStoreRomSql.env)
      @events        = ROM::Repositories::Events.new(rom)
      @event_streams = ROM::Repositories::EventStreams.new(rom)
    end

    def append_to_stream(events, stream_name, expected_version)
      @events.create(
        normalize_to_array(events),
        stream_name: stream_name,
        expected_version: ExpectedVersion.new(expected_version)
      )

      self
    rescue ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation => ex
      raise_error(ex)
    end

    def link_to_stream(event_ids, stream_name, expected_version)
      @events.link(normalize_to_array(event_ids), stream_name, ExpectedVersion.new(expected_version))

      self
    rescue ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation => ex
      raise_error(ex)
    end

    def delete_stream(stream_name)
      @events.delete_stream(stream_name)
    end

    def has_event?(event_id)
      @events.exist?(event_id)
    end

    def last_stream_event(stream_name)
      @events.read(:backward, stream_name, limit: 1).first
    end

    def read_events_forward(stream_name, after_event_id, count)
      @events.read(:forward, stream_name, from: after_event_id, limit: count)
    end

    def read_events_backward(stream_name, before_event_id, count)
      @events.read(:backward, stream_name, from: before_event_id, limit: count)
    end

    def read_stream_events_forward(stream_name)
      @events.read(:forward, stream_name)
    end

    def read_stream_events_backward(stream_name)
      @events.read(:backward, stream_name)
    end

    def read_all_streams_forward(after_event_id, count)
      read_events_forward(RubyEventStore::GLOBAL_STREAM, after_event_id, count)
    end

    def read_all_streams_backward(before_event_id, count)
      read_events_backward(RubyEventStore::GLOBAL_STREAM, before_event_id, count)
    end

    def read_event(event_id)
      @events.fetch(event_id)
    rescue ::ROM::TupleCountMismatchError
      raise RubyEventStore::EventNotFound.new(event_id)
    end

    def get_all_streams
      @event_streams.all
    end

    private

    def raise_error(ex)
      raise RubyEventStore::EventDuplicatedInStream if detect_index_violated(ex.message)
      raise RubyEventStore::WrongExpectedEventVersion
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
