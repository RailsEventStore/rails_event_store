require 'activerecord-import'

module RailsEventStoreActiveRecord
  class EventRepository
    InvalidDatabaseSchema = Class.new(StandardError)

    POSITION_SHIFT = 1

    def initialize
      verify_correct_schema_present
    end

    def append_to_stream(events, stream_name, expected_version)
      events = normalize_to_array(events)
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
        in_stream =
          events.flat_map.with_index do |event, index|
            position = expected_version + index + POSITION_SHIFT unless expected_version.equal?(:any)

            Event.create!(
              id: event.event_id,
              data: event.data,
              metadata: event.metadata,
              event_type: event.class,
            )

            {
              stream:   stream_name,
              position: position,
              event_id: event.event_id
            }
          end
        EventInStream.import(in_stream) unless stream_name.nil?
      end
      self
    rescue ActiveRecord::RecordNotUnique => e
      if detect_pkey_index_violated(e)
        raise RubyEventStore::EventDuplicatedInStream
      end
      raise RubyEventStore::WrongExpectedEventVersion
    end

    def delete_stream(stream_name)
      EventInStream.where(stream: stream_name).delete_all
    end

    def has_event?(event_id)
      Event.exists?(id: event_id)
    end

    def last_stream_event(stream_name)
      stream = EventInStream.where(stream: stream_name).order('position DESC, id DESC').first
      return unless stream

      build_event_entity(stream.event)
    end

    def read_events_forward(stream_name, after_event_id, count)
      stream = EventInStream.where(stream: stream_name)
      unless after_event_id.equal?(:head)
        after_event = stream.find_by!(event_id: after_event_id)
        stream = stream.where('id > ?', after_event)
      end

      stream.preload(:event).order('position ASC, id ASC').limit(count)
        .map { |r| build_event_entity(r.event) }
    end

    def read_events_backward(stream_name, before_event_id, count)
      stream = EventInStream.where(stream: stream_name)
      unless before_event_id.equal?(:head)
        before_event = stream.find_by!(event_id: before_event_id)
        stream = stream.where('id < ?', before_event)
      end

      stream.preload(:event).order('position DESC, id DESC').limit(count)
        .map { |r| build_event_entity(r.event) }
    end

    def read_stream_events_forward(stream_name)
      EventInStream.preload(:event).where(stream: stream_name).order('position ASC, id ASC')
        .map { |r| build_event_entity(r.event) }
    end

    def read_stream_events_backward(stream_name)
      EventInStream.preload(:event).where(stream: stream_name).order('position DESC, id DESC')
        .map { |r| build_event_entity(r.event) }
    end

    def read_all_streams_forward(after_event_id, count)
      events = Event.all
      unless after_event_id.equal?(:head)
        after_event = Event.find(after_event_id)
        events = Event.where('position > ?', after_event.position)
      end

      events.order('position ASC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_all_streams_backward(before_event_id, count)
      events = Event.all
      unless before_event_id.equal?(:head)
        before_event = Event.find(before_event_id)
        events = Event.where('position < ?', before_event.position)
      end

      events.order('position DESC').limit(count)
        .map(&method(:build_event_entity))
    end

    private

    def detect_pkey_index_violated(e)
      e.message.include?("index_event_store_events_on_id")  ||  # MySQL
      e.message.include?("event_store_events_pkey")         ||  # Postgresql
      e.message.include?("event_store_events.id")               # Sqlite3
    end

    def build_event_entity(event_record)
      event_record.event_type.constantize.new(
        event_id: event_record.id,
        metadata: event_record.metadata,
        data: event_record.data
      )
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
