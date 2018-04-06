module RailsEventStoreActiveRecord
  class EventRepositoryReader

    def has_event?(event_id)
      Event.exists?(id: event_id)
    end

    def last_stream_event(stream)
      record = EventInStream.where(stream: stream.name).order('position DESC, id DESC').first
      record && build_event_instance(record)
    end

    def read_event(event_id)
      event = Event.find(event_id)
      RubyEventStore::SerializedRecord.new(
        event_id:   event.id,
        metadata:   event.metadata,
        data:       event.data,
        event_type: event.event_type
      )
    rescue ActiveRecord::RecordNotFound
      raise RubyEventStore::EventNotFound.new(event_id)
    end

    def read(spec)
      stream = EventInStream.preload(:event).where(stream: spec.stream_name)
      stream = stream.limit(spec.count) if spec.limit?
      stream = stream.where(start_condition(spec)) unless spec.head?
      stream = stream.order(position: order(spec.direction)) unless spec.global_stream?
      stream = stream.order(id: order(spec.direction))

      Enumerator.new do |y|
        stream.each do |event_record|
          y << build_event_instance(event_record)
        end
      end
    end

    private

    def start_condition(specification)
      event_record =
        EventInStream.find_by!(event_id: specification.start, stream: specification.stream_name)
      case specification.direction
      when :forward
        ['id > ?', event_record]
      else
        ['id < ?', event_record]
      end
    end

    def order(direction)
      { forward: 'ASC', backward: 'DESC' }.fetch(direction)
    end

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
