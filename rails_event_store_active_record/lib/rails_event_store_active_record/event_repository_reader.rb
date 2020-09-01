# frozen_string_literal: true

module RailsEventStoreActiveRecord
  class EventRepositoryReader

    def has_event?(event_id)
      Event.exists?(id: event_id)
    end

    def last_stream_event(stream)
      record = EventInStream.where(stream: stream.name).order('position DESC, id DESC').first
      record && serialized_record(record)
    end

    def read(spec)
      raise RubyEventStore::ReservedInternalName if spec.stream.name.eql?(EventRepository::SERIALIZED_GLOBAL_STREAM_NAME)

      stream = read_scope(spec)

      if spec.batched?
        batch_reader = ->(offset_id, limit) do
          records = offset_id.nil? ? stream.limit(limit) : stream.where(start_offset_condition(spec, offset_id)).limit(limit)
          [records.map(&method(:serialized_record)), records.last]
        end
        BatchEnumerator.new(spec.batch_size, spec.limit, batch_reader).each
      elsif spec.first?
        record = stream.first
        serialized_record(record) if record
      elsif spec.last?
        record = stream.last
        serialized_record(record) if record
      else
        stream.map(&method(:serialized_record)).each
      end
    end

    def count(spec)
      raise RubyEventStore::ReservedInternalName if spec.stream.name.eql?(EventRepository::SERIALIZED_GLOBAL_STREAM_NAME)

      read_scope(spec).count
    end

    private

    def read_scope(spec)
      stream = EventInStream.preload(:event).where(stream: normalize_stream_name(spec))
      stream = stream.where(event_id: spec.with_ids) if spec.with_ids?
      stream = stream.joins(:event).where(event_store_events: {event_type: spec.with_types}) if spec.with_types?
      stream = stream.order(position: order(spec)) unless spec.stream.global?
      stream = stream.limit(spec.limit) if spec.limit?
      stream = stream.where(start_condition(spec)) if spec.start
      stream = stream.where(stop_condition(spec)) if spec.stop
      stream = stream.order(id: order(spec))
      stream
    end

    def normalize_stream_name(specification)
      specification.stream.global? ? EventRepository::SERIALIZED_GLOBAL_STREAM_NAME : specification.stream.name
    end

    def start_offset_condition(specification, record_id)
      condition = specification.forward? ? 'event_store_events_in_streams.id > ?' : 'event_store_events_in_streams.id < ?'
      [condition, record_id]
    end

    def stop_offset_condition(specification, record_id)
      condition = specification.forward? ? 'event_store_events_in_streams.id < ?' : 'event_store_events_in_streams.id > ?'
      [condition, record_id]
    end

    def start_condition(specification)
      start_offset_condition(specification,
        EventInStream.find_by!(event_id: specification.start, stream: normalize_stream_name(specification)))
    end

    def stop_condition(specification)
      stop_offset_condition(specification,
        EventInStream.find_by!(event_id: specification.stop, stream: normalize_stream_name(specification)))
    end

    def order(spec)
      spec.forward? ? 'ASC' : 'DESC'
    end

    def serialized_record(record)
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
