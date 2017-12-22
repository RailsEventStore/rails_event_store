require 'activerecord-import'

module RailsEventStoreActiveRecord
  class EventRepository
    InvalidDatabaseSchema = Class.new(StandardError)

    POSITION_SHIFT = 1

    def initialize(mapper: RubyEventStore::Mappers::Default.new)
      verify_correct_schema_present
      @mapper = mapper
    end

    def append_to_stream(events, stream_name, expected_version)
      add_to_stream(events, stream_name, expected_version, true) do |event|
        build_event_record(event).save!
        event.event_id
      end
    end

    def link_to_stream(event_ids, stream_name, expected_version)
      add_to_stream(event_ids, stream_name, expected_version, false) do |event_id|
        event_id
      end
    end

    def delete_stream(stream_name)
      EventInStream.where(stream: stream_name).delete_all
    end

    def has_event?(event_id)
      Event.exists?(id: event_id)
    end

    def last_stream_event(stream_name)
      record = EventInStream.where(stream: stream_name).order('position DESC, id DESC').first
      record && build_event_instance(record)
    end

    def read_events_forward(stream_name, after_event_id, count)
      stream = EventInStream.where(stream: stream_name)
      unless after_event_id.equal?(:head)
        after_event = stream.find_by!(event_id: after_event_id)
        stream = stream.where('id > ?', after_event)
      end

      stream.preload(:event).order('position ASC, id ASC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_events_backward(stream_name, before_event_id, count)
      stream = EventInStream.where(stream: stream_name)
      unless before_event_id.equal?(:head)
        before_event = stream.find_by!(event_id: before_event_id)
        stream = stream.where('id < ?', before_event)
      end

      stream.preload(:event).order('position DESC, id DESC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_stream_events_forward(stream_name)
      EventInStream.preload(:event).where(stream: stream_name).order('position ASC, id ASC')
        .map(&method(:build_event_instance))
    end

    def read_stream_events_backward(stream_name)
      EventInStream.preload(:event).where(stream: stream_name).order('position DESC, id DESC')
        .map(&method(:build_event_instance))
    end

    def read_all_streams_forward(after_event_id, count)
      stream = EventInStream.where(stream: RubyEventStore::GLOBAL_STREAM)
      unless after_event_id.equal?(:head)
        after_event = stream.find_by!(event_id: after_event_id)
        stream = stream.where('id > ?', after_event)
      end

      stream.preload(:event).order('id ASC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_all_streams_backward(before_event_id, count)
      stream = EventInStream.where(stream: RubyEventStore::GLOBAL_STREAM)
      unless before_event_id.equal?(:head)
        before_event = stream.find_by!(event_id: before_event_id)
        stream = stream.where('id < ?', before_event)
      end

      stream.preload(:event).order('id DESC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_event(event_id)
      event             = Event.find(event_id)
      serialized_record = RubyEventStore::SerializedRecord.new(
        event_id:   event.id,
        metadata:   event.metadata,
        data:       event.data,
        event_type: event.event_type
      )
      mapper.serialized_record_to_event(serialized_record)
    rescue ActiveRecord::RecordNotFound
      raise RubyEventStore::EventNotFound
    end

    def get_all_streams
      (["all"] + EventInStream.pluck(:stream))
        .uniq
        .map { |name| RubyEventStore::Stream.new(name) }
    end

    private

    attr_reader :mapper

    def add_to_stream(collection, stream_name, expected_version, include_global, &to_event_id)
      raise RubyEventStore::InvalidExpectedVersion if stream_name.eql?(RubyEventStore::GLOBAL_STREAM) && !expected_version.equal?(:any)

      collection = normalize_to_array(collection)
      expected_version =
        case expected_version
        when Integer, :any
          expected_version
        when :none
          -1
        when :auto
          eis = EventInStream.where(stream: stream_name).order("position DESC").first
          (eis && eis.position) || -1
        else
          raise RubyEventStore::InvalidExpectedVersion
        end

      ActiveRecord::Base.transaction(requires_new: true) do
        in_stream = collection.flat_map.with_index do |element, index|
          position = unless expected_version.equal?(:any)
            expected_version + index + POSITION_SHIFT
          end
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
      if detect_pkey_index_violated(e)
        raise RubyEventStore::EventDuplicatedInStream
      end
      raise RubyEventStore::WrongExpectedEventVersion
    end

    def detect_pkey_index_violated(e)
      e.message.include?("for key 'PRIMARY'")       ||  # MySQL
      e.message.include?("event_store_events_pkey") ||  # Postgresql
      e.message.include?("event_store_events.id")       # Sqlite3
    end

    def build_event_record(event)
      serialized_record = mapper.event_to_serialized_record(event)
      Event.new(
        id:         serialized_record.event_id,
        data:       serialized_record.data,
        metadata:   serialized_record.metadata,
        event_type: serialized_record.event_type
      )
    end

    def build_event_instance(record)
      serialized_record = RubyEventStore::SerializedRecord.new(
        event_id:         record.event.id,
        metadata:   record.event.metadata,
        data:       record.event.data,
        event_type: record.event.event_type
      )
      mapper.serialized_record_to_event(serialized_record)
    end

    def normalize_to_array(events)
      [*events]
    end

    def incorrect_schema_message
      <<-MESSAGE
Oh no!

It seems you're using RailsEventStoreActiveRecord::EventRepository
with incompaible database schema.

We've redesigned database structure in order to fix several concurrency-related
bugs. This repository is intended to work on that improved data layout.

We've prepared migration that would take you from old schema to new one.
This migration must be run offline -- take that into consideration:

  rails g rails_event_store_active_record:v1_v2_migration
  rake db:migrate


If you cannot migrate right now -- you can for some time continue using
old repository. In order to do so, change configuration accordingly:

  config.event_store = RailsEventStore::Client.new(
                         repository: RailsEventStoreActiveRecord::LegacyEventRepository.new
                       )


      MESSAGE
    end

    def verify_correct_schema_present
      return unless ActiveRecord::Base.connected?
      legacy_columns  = ["id", "stream", "event_type", "event_id", "metadata", "data", "created_at"]
      current_columns = ActiveRecord::Base.connection.columns("event_store_events").map(&:name)
      raise InvalidDatabaseSchema.new(incorrect_schema_message) if legacy_columns.eql?(current_columns)
    end
  end
end
