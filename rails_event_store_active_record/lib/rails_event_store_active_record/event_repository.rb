require 'activerecord-import'

module RailsEventStoreActiveRecord
  class EventRepository
    def initialize(adapter: Event)
      @adapter = adapter
    end
    attr_reader :adapter

    def append_to_stream(events, stream_name, expected_version)
      events = [*events]
      expected_version   = case expected_version
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
        position = if expected_version == :any
          nil
        else
          expected_version + index + 1
        end
        Event.create!(
          id: event.event_id,
          data: event.data,
          metadata: event.metadata,
          event_type: event.class,
        )
        [EventInStream.new(
          stream:   stream_name,
          position: position,
          event_id: event.event_id
        ),EventInStream.new(
          stream: "__global__",
          position: nil,
          event_id: event.event_id
        )]
      end
      EventInStream.import(in_stream)
      self
    rescue ActiveRecord::RecordNotUnique
      raise RubyEventStore::WrongExpectedEventVersion
    end

    def delete_stream(stream_name)
      condition = {stream: stream_name}
      adapter.destroy_all condition
    end

    def has_event?(event_id)
      Event.exists?(id: event_id)
    end

    def last_stream_event(stream_name)
      build_event_entity(
        EventInStream.preload(:event).where(stream: stream_name).order('position DESC, id DESC').first
      )
    end

    def read_events_forward(stream_name, after_event_id, count)
      stream = EventInStream.where(stream: stream_name)
      unless after_event_id.equal?(:head)
        after_event = stream.find_by!(event_id: after_event_id)
        stream = stream.where('id > ?', after_event.id)
      end

      stream.preload(:event).order('position ASC, id ASC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_events_backward(stream_name, before_event_id, count)
      stream = EventInStream.where(stream: stream_name)
      unless before_event_id.equal?(:head)
        before_event = stream.find_by!(event_id: before_event_id)
        stream = stream.where('id < ?', before_event.id)
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

    def read_all_streams_forward(start_event_id, count)
      stream = EventInStream.where(stream: "__global__")
      unless start_event_id.equal?(:head)
        stream = stream.where('event_id > ?', start_event_id)
      end

      stream.preload(:event).order('id ASC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_all_streams_backward(start_event_id, count)
      stream = EventInStream.where(stream: "__global__")
      unless start_event_id.equal?(:head)
        stream = stream.where('event_id < ?', start_event_id)
      end

      stream.preload(:event).order('id DESC').limit(count)
        .map(&method(:build_event_entity))
    end

    private

    def build_event_entity(record)
      return nil unless record
      record.event.event_type.constantize.new(
        event_id: record.event.id,
        metadata: record.event.metadata,
        data: record.event.data
      )
    end
  end
end
