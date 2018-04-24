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
        event_id: event.id,
        metadata: event.metadata,
        data: event.data,
        event_type: event.event_type
      )
    rescue ActiveRecord::RecordNotFound
      raise RubyEventStore::EventNotFound.new(event_id)
    end


    def read(spec)
      if spec.global_stream?
        stream = Event.order(position: order(spec.direction))
        stream = stream.limit(spec.count) if spec.limit?
        stream = stream.where(start_condition_in_global_stream(spec)) unless spec.head?
      else
        stream =
          EventInStream
            .preload(:event)
            .where(stream: spec.stream_name)
            .order(position: order(spec.direction), id: order(spec.direction))
        stream = stream.limit(spec.count) if spec.limit?
        stream = stream.where(start_condition(spec)) unless spec.head?
      end

      if spec.batched?
        batch_reader = ->(offset, limit) { stream.offset(offset).limit(limit).map(&method(:build_event_instance)) }
        RubyEventStore::BatchEnumerator.new(spec.batch_size, total_limit(spec), batch_reader).each
      else
        stream.map(&method(:build_event_instance)).each
      end
    end

    private

    def total_limit(specification)
      specification.limit? ? specification.count : Float::INFINITY
    end

    def start_condition_in_global_stream(specification)
      event_record =
        Event.find_by!(id: specification.start)
      case specification.direction
      when :forward
        ['position > ?', event_record.position]
      else
        ['position < ?', event_record.position]
      end
    end

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
      {forward: 'ASC', backward: 'DESC'}.fetch(direction)
    end

    def build_event_instance(record)
      record = record.event if record.respond_to?(:event)

      RubyEventStore::SerializedRecord.new(
        event_id: record.id,
        metadata: record.metadata,
        data: record.data,
        event_type: record.event_type
      )
    end
  end

  private_constant(:EventRepositoryReader)
end
