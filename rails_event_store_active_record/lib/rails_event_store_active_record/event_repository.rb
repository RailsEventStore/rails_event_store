require 'activerecord-import'
require 'ruby_event_store/repository'

module RailsEventStoreActiveRecord
  class EventRepository
    include RubyEventStore::Repository

    def initialize(mapper: RubyEventStore::Mappers::Default.new)
      @mapper        = mapper
      @repo_reader   = EventRepositoryReader.new(mapper)
    end

    def append_to_stream(event_ids, stream_name, expected_version)
      event_ids = normalize_to_array(event_ids)
      add_to_stream(event_ids, stream_name, expected_version, true) do |event|
        build_event_record(event).save!
        event.event_id
      end
    end

    def link_to_stream(event_ids, stream_name, expected_version)
      (normalize_to_array(event_ids) - Event.where(id: event_ids).pluck(:id)).each do |id|
        raise RubyEventStore::EventNotFound.new(id)
      end
      event_ids = normalize_to_array(event_ids)
      add_to_stream(event_ids, stream_name, expected_version, nil) do |event_id|
        event_id
      end
    end

    def delete_stream(stream_name)
      EventInStream.where(stream: stream_name).delete_all
    end

    def has_event?(event_id)
      @repo_reader.has_event?(event_id)
    end

    def last_stream_event(stream_name)
      @repo_reader.last_stream_event(stream_name)
    end

    def read_events_forward(stream_name, after_event_id, count)
      @repo_reader.read_events_forward(stream_name, after_event_id, count)
    end

    def read_events_backward(stream_name, before_event_id, count)
      @repo_reader.read_events_backward(stream_name, before_event_id, count)
    end

    def read_stream_events_forward(stream_name)
      @repo_reader.read_stream_events_forward(stream_name)
    end

    def read_stream_events_backward(stream_name)
      @repo_reader.read_stream_events_backward(stream_name)
    end

    def read_all_streams_forward(after_event_id, count)
      @repo_reader.read_all_streams_forward(after_event_id, count)
    end

    def read_all_streams_backward(before_event_id, count)
      @repo_reader.read_all_streams_backward(before_event_id, count)
    end

    def read_event(event_id)
      @repo_reader.read_event(event_id)
    end

    def get_all_streams
      @repo_reader.get_all_streams
    end

    def add_metadata(event, key, value)
      @mapper.add_metadata(event, key, value)
    end

    private

    def append(collection, stream_name, expected_version, include_global, &to_event_id)
      ActiveRecord::Base.transaction(requires_new: true) do
        in_stream = collection.flat_map.with_index do |element, index|
          position = compute_position(expected_version, index)
          event_id = to_event_id.call(element)
          collection = []
          collection.unshift({
            stream: RubyEventStore::GLOBAL_STREAM,
            position: nil,
            event_id: event_id
          }) if include_global
          collection.unshift({
            stream:   stream_name,
            position: position,
            event_id: event_id
          }) unless stream_name.eql?(RubyEventStore::GLOBAL_STREAM)
          collection
        end
        EventInStream.import(in_stream)
      end
      self
    rescue ActiveRecord::RecordNotUnique => e
      raise_error(e)
    end

    def raise_error(e)
      raise RubyEventStore::EventDuplicatedInStream if detect_index_violated(e.message)
      raise RubyEventStore::WrongExpectedEventVersion
    end

    def last_position_for(stream_name)
      EventInStream.where(stream: stream_name).order("position DESC").limit(1).select(:position).pluck(:position).first
    end

    def detect_index_violated(message)
      IndexViolationDetector.new.detect(message)
    end

    def build_event_record(event)
      serialized_record = @mapper.event_to_serialized_record(event)
      Event.new(
        id:         serialized_record.event_id,
        data:       serialized_record.data,
        metadata:   serialized_record.metadata,
        event_type: serialized_record.event_type
      )
    end

    def verify_correct_schema_present
      CorrectSchemaVerifier.new.verify
    end
  end
end
