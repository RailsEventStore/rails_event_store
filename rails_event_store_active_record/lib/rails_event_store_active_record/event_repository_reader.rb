# frozen_string_literal: true

module RailsEventStoreActiveRecord
  class EventRepositoryReader

    def initialize(event_klass, stream_klass, serializer)
      @event_klass = event_klass
      @stream_klass = stream_klass
      @serializer = serializer
    end

    def has_event?(event_id)
      @event_klass.exists?(id: event_id)
    end

    def last_stream_event(stream)
      record_ = @stream_klass.where(stream: stream.name).order('position DESC, id DESC').first
      record(record_) if record_
    end

    def read(spec)
      raise RubyEventStore::ReservedInternalName if spec.stream.name.eql?(EventRepository::SERIALIZED_GLOBAL_STREAM_NAME)

      stream = read_scope(spec)

      if spec.batched?
        batch_reader = ->(offset_id, limit) do
          records = offset_id.nil? ? stream.limit(limit) : stream.where(start_offset_condition(spec, offset_id)).limit(limit)
          [records.map(&method(:record)), records.last]
        end
        BatchEnumerator.new(spec.batch_size, spec.limit, batch_reader).each
      elsif spec.first?
        record_ = stream.first
        record(record_) if record_
      elsif spec.last?
        record_ = stream.last
        record(record_) if record_
      else
        stream.map(&method(:record)).each
      end
    end

    def count(spec)
      raise RubyEventStore::ReservedInternalName if spec.stream.name.eql?(EventRepository::SERIALIZED_GLOBAL_STREAM_NAME)

      read_scope(spec).count
    end

    private
    attr_reader :serializer

    def read_scope(spec)
      stream = @stream_klass.preload(:event).where(stream: normalize_stream_name(spec))
      stream = stream.where(event_id: spec.with_ids) if spec.with_ids?
      stream = stream.joins(:event).where(event_store_events: {event_type: spec.with_types}) if spec.with_types?
      stream = stream.order(position: order(spec)) unless spec.stream.global?
      stream = stream.limit(spec.limit) if spec.limit?
      stream = stream.where(start_condition(spec)) if spec.start
      stream = stream.where(stop_condition(spec))  if spec.stop
      stream = stream.joins(:event).where(older_than_condition(spec))          if spec.older_than
      stream = stream.joins(:event).where(older_than_or_equal_condition(spec)) if spec.older_than_or_equal
      stream = stream.joins(:event).where(newer_than_condition(spec))          if spec.newer_than
      stream = stream.joins(:event).where(newer_than_or_equal_condition(spec)) if spec.newer_than_or_equal
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
        @stream_klass.find_by!(event_id: specification.start, stream: normalize_stream_name(specification)))
    end

    def stop_condition(specification)
      stop_offset_condition(specification,
        @stream_klass.find_by!(event_id: specification.stop, stream: normalize_stream_name(specification)))
    end

    def older_than_condition(specification)
      ['event_store_events.created_at < ?', specification.older_than]
    end

    def older_than_or_equal_condition(specification)
      ['event_store_events.created_at <= ?', specification.older_than_or_equal]
    end

    def newer_than_condition(specification)
      ['event_store_events.created_at > ?', specification.newer_than]
    end

    def newer_than_or_equal_condition(specification)
      ['event_store_events.created_at >= ?', specification.newer_than_or_equal]
    end


    def order(spec)
      spec.forward? ? 'ASC' : 'DESC'
    end

    def record(record)
      RubyEventStore::SerializedRecord.new(
        event_id: record.event.id,
        metadata: record.event.metadata,
        data: record.event.data,
        event_type: record.event.event_type,
        timestamp: record.event.created_at.iso8601(RubyEventStore::TIMESTAMP_PRECISION),
      ).deserialize(serializer)
    end
  end

  private_constant(:EventRepositoryReader)
end
