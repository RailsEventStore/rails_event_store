require 'activerecord-import'

module RailsEventStoreActiveRecord
  class EventRepository
    POSITION_SHIFT = 1

    def append_to_stream(events, stream_name, expected_version)
      raise RubyEventStore::InvalidExpectedVersion if stream_name.eql?(RubyEventStore::GLOBAL_STREAM) && !expected_version.equal?(:any)

      events = normalize_to_array(events)
      expected_version =
        case expected_version
        when nil
          raise RubyEventStore::InvalidExpectedVersion
        when :none
          -1
        when :auto
          eis = EventInStream.where(stream: stream_name).order("position DESC").first
          (eis && eis.position) || -1
        else
          expected_version
        end

      in_stream = events.flat_map.with_index do |event, index|
        position = unless expected_version.equal?(:any)
          expected_version + index + POSITION_SHIFT
        end
        Event.create!(
          id: event.event_id,
          data: event.data,
          metadata: event.metadata,
          event_type: event.class,
        )
        events = [{
          stream: RubyEventStore::GLOBAL_STREAM,
          event_id: event.event_id
        }]
        events.unshift({
          stream:   stream_name,
          position: position,
          event_id: event.event_id
        }) unless stream_name.eql?(RubyEventStore::GLOBAL_STREAM)
        events
      end
      EventInStream.import(in_stream)
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
      build_event_entity(
        EventInStream.where(stream: stream_name).order('position DESC, id DESC').first
      )
    end

    def read_events_forward(stream_name, after_event_id, count)
      stream = EventInStream.where(stream: stream_name)
      unless after_event_id.equal?(:head)
        after_event = stream.find_by!(event_id: after_event_id)
        stream = stream.where('id > ?', after_event)
      end

      stream.preload(:event).order('position ASC, id ASC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_events_backward(stream_name, before_event_id, count)
      stream = EventInStream.where(stream: stream_name)
      unless before_event_id.equal?(:head)
        before_event = stream.find_by!(event_id: before_event_id)
        stream = stream.where('id < ?', before_event)
      end

      stream.preload(:event).order('position DESC, id DESC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_stream_events_forward(stream_name)
      EventInStream.preload(:event).where(stream: stream_name).order('position ASC, id ASC')
        .map(&method(:build_event_entity))
    end

    def read_stream_events_backward(stream_name)
      EventInStream.preload(:event).where(stream: stream_name).order('position DESC, id DESC')
        .map(&method(:build_event_entity))
    end

    def read_all_streams_forward(after_event_id, count)
      stream = EventInStream.where(stream: RubyEventStore::GLOBAL_STREAM)
      unless after_event_id.equal?(:head)
        after_event = stream.find_by!(event_id: after_event_id)
        stream = stream.where('id > ?', after_event)
      end

      stream.preload(:event).order('id ASC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_all_streams_backward(before_event_id, count)
      stream = EventInStream.where(stream: RubyEventStore::GLOBAL_STREAM)
      unless before_event_id.equal?(:head)
        before_event = stream.find_by!(event_id: before_event_id)
        stream = stream.where('id < ?', before_event)
      end

      stream.preload(:event).order('id DESC').limit(count)
        .map(&method(:build_event_entity))
    end

    private

    def detect_pkey_index_violated(e)
      e.message.include?("for key 'PRIMARY'")       ||  # MySQL
      e.message.include?("event_store_events_pkey") ||  # Postgresql
      e.message.include?("event_store_events.id")       # Sqlite3
    end

    def build_event_entity(record)
      return nil unless record
      record.event.event_type.constantize.new(
        event_id: record.event.id,
        metadata: record.event.metadata,
        data: record.event.data
      )
    end

    def normalize_to_array(events)
      [*events]
    end
  end
end
