module RailsEventStoreActiveRecord
  class EventRepositoryReader

    def has_event?(event_id)
      Event.exists?(id: event_id)
    end

    def last_stream_event(stream)
      record = EventInStream.where(stream: stream.name).order('position DESC, id DESC').first
      record && build_event_instance(record)
    end

    def read_events_forward(stream, after_event_id, count)
      events = EventInStream.where(stream: stream.name)
      unless after_event_id.equal?(:head)
        after_event = events.find_by!(event_id: after_event_id)
        events = events.where('id > ?', after_event)
      end

      events = events.order('position ASC') unless stream.global?
      events.preload(:event).order('id ASC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_events_backward(stream, before_event_id, count)
      events = EventInStream.where(stream: stream.name)
      unless before_event_id.equal?(:head)
        before_event = events.find_by!(event_id: before_event_id)
        events = events.where('id < ?', before_event)
      end

      events = events.order('position DESC') unless stream.global?
      events.preload(:event).order('id DESC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_stream_events_forward(stream)
      events = EventInStream.preload(:event).where(stream: stream.name)
      events = events.order('position ASC') unless stream.global?
      events = events.order('id ASC')
      events.map(&method(:build_event_instance))
    end

    def read_stream_events_backward(stream)
      events = EventInStream.preload(:event).where(stream: stream.name)
      events = events.order('position DESC') unless stream.global?
      events = events.order('id DESC')
      events.map(&method(:build_event_instance))
    end

    def read_all_streams_forward(after_event_id, count)
      events = EventInStream.where(stream: RubyEventStore::GLOBAL_STREAM)
      unless after_event_id.equal?(:head)
        after_event = events.find_by!(event_id: after_event_id)
        events = events.where('id > ?', after_event)
      end

      events.preload(:event).order('id ASC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_all_streams_backward(before_event_id, count)
      events = EventInStream.where(stream: RubyEventStore::GLOBAL_STREAM)
      unless before_event_id.equal?(:head)
        before_event = events.find_by!(event_id: before_event_id)
        events = events.where('id < ?', before_event)
      end

      events.preload(:event).order('id DESC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_event(event_id)
      event             = Event.find(event_id)
      RubyEventStore::SerializedRecord.new(
        event_id:   event.id,
        metadata:   event.metadata,
        data:       event.data,
        event_type: event.event_type
      )
    rescue ActiveRecord::RecordNotFound
      raise RubyEventStore::EventNotFound.new(event_id)
    end

    def get_all_streams
      (["all"] + EventInStream.order(:id).pluck(:stream))
        .uniq
        .map { |name| RubyEventStore::Stream.new(name) }
    end

    private

    def build_event_instance(record)
      RubyEventStore::SerializedRecord.new(
        event_id:   record.event.id,
        metadata:   record.event.metadata,
        data:       record.event.data,
        event_type: record.event.event_type
      )
    end
  end

  private_constant(:EventRepositoryReader)
end
