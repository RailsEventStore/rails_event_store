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
      raise RubyEventStore::ReservedInternalName if spec.stream_name.eql?(EventRepository::SERIALIZED_GLOBAL_STREAM_NAME)

      stream = EventInStream.preload(:event).where(stream: normalize_stream_name(spec))
      stream = stream.order(position: order(spec)) unless spec.global_stream?
      stream = stream.limit(spec.count) if spec.limit?
      stream = stream.where(start_condition(spec)) unless spec.head?
      stream = stream.order(id: order(spec))

      if spec.batched?
        batch_reader = ->(offset, limit) { stream.offset(offset).limit(limit).map(&method(:build_event_instance)) }
        RubyEventStore::BatchEnumerator.new(spec.batch_size, spec.count, batch_reader).each
      elsif spec.first?
        record = stream.first
        build_event_instance(record) if record
      elsif spec.last?
        record = stream.last
        build_event_instance(record) if record
      else
        stream.map(&method(:build_event_instance)).each
      end
    end

    private

    def normalize_stream_name(specification)
      specification.global_stream? ? EventRepository::SERIALIZED_GLOBAL_STREAM_NAME : specification.stream_name
    end

    def start_condition(specification)
      event_record =
        EventInStream.find_by!(event_id: specification.start, stream: normalize_stream_name(specification))
      condition = specification.forward? ? 'id > ?' : 'id < ?'
      [condition, event_record]
    end

    def order(spec)
      spec.forward? ? 'ASC' : 'DESC'
    end

    def build_event_instance(record)
      RubyEventStore::SerializedRecord.new(
        event_id: record.event.id,
        metadata: record.event.metadata,
        data: record.event.data,
        event_type: record.event.event_type
      )
    end
  end

  private_constant(:EventRepositoryReader)
end
