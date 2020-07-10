# frozen_string_literal: true

module RailsEventStoreActiveRecord
  class EventRepositoryReader

    def has_event?(event_id)
      Event.exists?(id: event_id)
    end

    def last_stream_event(stream)
      record = EventInStream.where(stream: stream.name).order('position DESC, id DESC').first
      record && build_event_instance(record)
    end

    def read(spec)
      raise RubyEventStore::ReservedInternalName if spec.stream.name.eql?(EventRepository::SERIALIZED_GLOBAL_STREAM_NAME)

      stream = read_scope(spec)

      if spec.batched?
        offset_condition = spec.forward? ? 'event_store_events_in_streams.id > ?' : 'event_store_events_in_streams.id < ?'
        initial_id = stream.first&.id.to_i + (spec.forward? ? -1 : +1)
        batch_reader = ->(offset_id, limit) { stream.where([offset_condition, offset_id]).limit(limit) }
        BatchEnumerator.new(spec.batch_size, spec.limit, batch_reader, initial_id, method(:build_event_instance)).each
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

    def start_condition(specification)
      event_record =
        EventInStream.find_by!(event_id: specification.start, stream: normalize_stream_name(specification))
      condition = specification.forward? ? 'event_store_events_in_streams.id > ?' : 'event_store_events_in_streams.id < ?'
      [condition, event_record]
    end

    def stop_condition(specification)
      event_record =
        EventInStream.find_by!(event_id: specification.stop, stream: normalize_stream_name(specification))
      condition = specification.forward? ? 'event_store_events_in_streams.id < ?' : 'event_store_events_in_streams.id > ?'
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

  class BatchEnumerator
    def initialize(batch_size, total_limit, reader, offset_id, builder)
      @batch_size = batch_size
      @total_limit = total_limit
      @reader = reader
      @builder = builder
      @offset_id = offset_id
    end

    def each
      return to_enum unless block_given?

      0.step(total_limit - 1, batch_size) do |batch_offset|
        batch_limit  = [batch_size, total_limit - batch_offset].min
        records  = reader.call(@offset_id, batch_limit)

        break if records.empty?
        @offset_id = records.last.id
        yield records.map(&builder)
      end
    end

    private

    attr_accessor :batch_size, :total_limit, :reader, :builder
  end

  private_constant(:EventRepositoryReader)
  private_constant(:BatchEnumerator)
end
