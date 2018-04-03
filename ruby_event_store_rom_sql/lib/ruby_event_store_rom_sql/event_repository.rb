module RubyEventStoreRomSql
  class EventRepository
    POSITION_SHIFT = 1.freeze
    POSITION_DEFAULT = -1.freeze

    def initialize(rom: RubyEventStoreRomSql.env, mapper: RubyEventStore::Mappers::Default.new)
      @events        = ROM::Repositories::Events.new(rom)
      @event_streams = ROM::Repositories::EventStreams.new(rom)
      @mapper        = mapper
    end

    def append_to_stream(events, stream_name, expected_version)
      add_to_stream(events, stream_name, expected_version, true) do |event|
        @events.create(map_to_serialized_record(event))
        event.event_id
      end
    end

    def link_to_stream(event_ids, stream_name, expected_version)
      @events.detect_invalid_event_ids(normalize_to_array(event_ids)).each do |id|
        raise RubyEventStore::EventNotFound.new(id)
      end
      add_to_stream(normalize_to_array(event_ids), stream_name, expected_version, nil) do |event_id|
        event_id
      end
    end

    def delete_stream(stream_name)
      @events.delete_stream(stream_name)
    end

    def has_event?(event_id)
      @events.exist?(event_id)
    end

    def last_stream_event(stream_name)
      @events.read(:backward, stream_name, limit: 1).map(&method(:map_to_event)).first
    end

    def read_events_forward(stream_name, after_event_id, count)
      @events.read(:forward, stream_name, from: after_event_id, limit: count).map(&method(:map_to_event))
    end

    def read_events_backward(stream_name, before_event_id, count)
      @events.read(:backward, stream_name, from: before_event_id, limit: count).map(&method(:map_to_event))
    end

    def read_stream_events_forward(stream_name)
      @events.read(:forward, stream_name).map(&method(:map_to_event))
    end

    def read_stream_events_backward(stream_name)
      @events.read(:backward, stream_name).map(&method(:map_to_event))
    end

    def read_all_streams_forward(after_event_id, count)
      read_events_forward(RubyEventStore::GLOBAL_STREAM, after_event_id, count)
    end

    def read_all_streams_backward(before_event_id, count)
      read_events_backward(RubyEventStore::GLOBAL_STREAM, before_event_id, count)
    end

    def read_event(event_id)
      map_to_event @events.fetch(event_id)
    end

    def get_all_streams
      @event_streams.all
    end

    def add_metadata(event, key, value)
      @mapper.add_metadata(event, key, value)
    end

    private

    def add_to_stream(event_ids, stream_name, expected_version, include_global, &to_event_id)
      raise RubyEventStore::InvalidExpectedVersion if !expected_version.equal?(:any) &&
                                                      stream_name.eql?(RubyEventStore::GLOBAL_STREAM)

      event_ids = normalize_to_array(event_ids)
      expected_version = normalize_expected_version(expected_version, stream_name)

      # TODO: Move this into repository (don't expose db internals)!!
      @event_streams.event_streams.transaction(savepoint: true) do
        in_stream = event_ids.flat_map.with_index do |event_id, index|
          position = compute_position(expected_version, index)
          event_id = to_event_id.call(event_id)

          collection = []
          collection.unshift(
            stream: RubyEventStore::GLOBAL_STREAM,
            # position: nil,
            event_id: event_id
          ) if include_global

          collection.unshift(
            stream:   stream_name,
            position: position,
            event_id: event_id
          ) unless stream_name.eql?(RubyEventStore::GLOBAL_STREAM)

          collection
        end

        @event_streams.import(in_stream)
      end
      self
    rescue ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation => e
      raise RubyEventStore::EventDuplicatedInStream if detect_index_violated(e.message)
      raise RubyEventStore::WrongExpectedEventVersion
    end

    def compute_position(expected_version, offset)
      unless expected_version.equal?(:any)
        expected_version + offset + POSITION_SHIFT
      end
    end

    def normalize_expected_version(expected_version, stream_name)
      case expected_version
      when Integer, :any
        expected_version
      when :none
        POSITION_DEFAULT
      when :auto
        @events.last_position_for(stream_name) || POSITION_DEFAULT
      else
        raise RubyEventStore::InvalidExpectedVersion
      end
    end

    def detect_index_violated(message)
      IndexViolationDetector.new.detect(message)
    end

    def normalize_to_array(events)
      return *Array(events)
    end

    def map_to_serialized_record(event)
      @mapper.event_to_serialized_record(event)
    end

    def map_to_event(events)
      mapped = Array(events).map(&@mapper.method(:serialized_record_to_event))
      events.is_a?(Enumerable) ? mapped : mapped.first
    end
  end
end
