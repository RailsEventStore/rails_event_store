module RailsEventStoreActiveRecord
  class EventRepositoryReader

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

      stream = stream.order('position ASC') unless stream_name.eql?(RubyEventStore::GLOBAL_STREAM)
      stream.preload(:event).order('id ASC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_events_backward(stream_name, before_event_id, count)
      stream = EventInStream.where(stream: stream_name)
      unless before_event_id.equal?(:head)
        before_event = stream.find_by!(event_id: before_event_id)
        stream = stream.where('id < ?', before_event)
      end

      stream = stream.order('position DESC') unless stream_name.eql?(RubyEventStore::GLOBAL_STREAM)
      stream.preload(:event).order('id DESC').limit(count)
        .map(&method(:build_event_instance))
    end

    def read_stream_events_forward(stream_name)
      stream = EventInStream.preload(:event).where(stream: stream_name)
      stream = stream.order('position ASC') unless stream_name.eql?(RubyEventStore::GLOBAL_STREAM)
      stream = stream.order('id ASC')
      stream.map(&method(:build_event_instance))
    end

    def read_stream_events_backward(stream_name)
      stream = EventInStream.preload(:event).where(stream: stream_name)
      stream = stream.order('position DESC') unless stream_name.eql?(RubyEventStore::GLOBAL_STREAM)
      stream = stream.order('id DESC')
      stream.map(&method(:build_event_instance))
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
