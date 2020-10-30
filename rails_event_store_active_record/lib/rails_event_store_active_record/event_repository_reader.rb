# frozen_string_literal: true

module RailsEventStoreActiveRecord
  class EventRepositoryReader

    def initialize(event_klass, stream_klass, serializer)
      @event_klass = event_klass
      @stream_klass = stream_klass
      @serializer = serializer
    end

    def has_event?(event_id)
      @event_klass.exists?(event_id: event_id)
    end

    def last_stream_event(stream)
      record_ = @stream_klass.where(stream: stream.name).order('position DESC, id DESC').first
      record(record_) if record_
    end

    def read(spec)
      stream = read_scope(spec)

      if spec.batched?
        batch_reader = ->(offset_id, limit) do
          search_in = spec.stream.global? ? @event_klass.table_name : @stream_klass.table_name
          records = offset_id.nil? ? stream.limit(limit) : stream.where(start_offset_condition(spec, offset_id, search_in)).limit(limit)
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
      read_scope(spec).count
    end

    private
    attr_reader :serializer

    def read_scope(spec)
      if spec.stream.global?
        stream = @event_klass
        stream = stream.where(event_id: spec.with_ids)                           if spec.with_ids?
        stream = stream.where(event_type: spec.with_types)                       if spec.with_types?
        stream = ordered(stream, spec)
        stream = stream.limit(spec.limit)                                        if spec.limit?
        stream = stream.where(start_condition_in_global_stream(spec))            if spec.start
        stream = stream.where(stop_condition_in_global_stream(spec))             if spec.stop
        stream = stream.where(older_than_condition(spec))          if spec.older_than
        stream = stream.where(older_than_or_equal_condition(spec)) if spec.older_than_or_equal
        stream = stream.where(newer_than_condition(spec))          if spec.newer_than
        stream = stream.where(newer_than_or_equal_condition(spec)) if spec.newer_than_or_equal
        stream.order(id: order(spec))
      else
        stream = @stream_klass.preload(:event).where(stream: spec.stream.name)
        stream = stream.where(event_id: spec.with_ids)                                                if spec.with_ids?
        stream = stream.where(@event_klass.table_name => {event_type: spec.with_types}) if spec.with_types?
        stream = ordered(stream.joins(:event), spec)
        stream = stream.order(position: order(spec), id: order(spec))
        stream = stream.limit(spec.limit)                                        if spec.limit?
        stream = stream.where(start_condition(spec))                             if spec.start
        stream = stream.where(stop_condition(spec))                              if spec.stop
        stream = stream.where(older_than_condition(spec))          if spec.older_than
        stream = stream.where(older_than_or_equal_condition(spec)) if spec.older_than_or_equal
        stream = stream.where(newer_than_condition(spec))          if spec.newer_than
        stream = stream.where(newer_than_or_equal_condition(spec)) if spec.newer_than_or_equal
        stream
      end
    end

    def ordered(stream, spec)
      case spec.time_sort_by
      when :as_at
        stream.order("#{@event_klass.table_name}.created_at #{order(spec)}")
      when :as_of
        stream.order("#{@event_klass.table_name}.valid_at #{order(spec)}")
      else
        stream
      end
    end

    def start_offset_condition(specification, record_id, search_in)
      condition = "#{search_in}.id #{specification.forward? ? '>' : '<'} ?"
      [condition, record_id]
    end

    def stop_offset_condition(specification, record_id, search_in)
      condition = "#{search_in}.id #{specification.forward? ? '<' : '>'} ?"
      [condition, record_id]
    end

    def start_condition(specification)
      start_offset_condition(specification,
        @stream_klass.find_by!(event_id: specification.start, stream: specification.stream.name),
        @stream_klass.table_name)
    end

    def stop_condition(specification)
      stop_offset_condition(specification,
        @stream_klass.find_by!(event_id: specification.stop, stream: specification.stream.name),
        @stream_klass.table_name)
    end

    def start_condition_in_global_stream(specification)
      start_offset_condition(specification,
        @event_klass.find_by!(event_id: specification.start),
        @event_klass.table_name)
    end

    def stop_condition_in_global_stream(specification)
      stop_offset_condition(specification,
        @event_klass.find_by!(event_id: specification.stop),
        @event_klass.table_name)
    end

    def older_than_condition(specification)
      ["#{@event_klass.table_name}.created_at < ?", specification.older_than]
    end

    def older_than_or_equal_condition(specification)
      ["#{@event_klass.table_name}.created_at <= ?", specification.older_than_or_equal]
    end

    def newer_than_condition(specification)
      ["#{@event_klass.table_name}.created_at > ?", specification.newer_than]
    end

    def newer_than_or_equal_condition(specification)
      ["#{@event_klass.table_name}.created_at >= ?", specification.newer_than_or_equal]
    end

    def order(spec)
      spec.forward? ? 'ASC' : 'DESC'
    end

    def record(record)
      record = record.event if @stream_klass === record

      RubyEventStore::SerializedRecord.new(
        event_id: record.event_id,
        metadata: record.metadata,
        data: record.data,
        event_type: record.event_type,
        timestamp: record.created_at.iso8601(RubyEventStore::TIMESTAMP_PRECISION),
        valid_at: (record.valid_at || record.created_at).iso8601(RubyEventStore::TIMESTAMP_PRECISION),
      ).deserialize(serializer)
    end
  end

  private_constant(:EventRepositoryReader)
end
