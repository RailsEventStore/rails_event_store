# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
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
        record_ = @stream_klass.where(stream: stream.name).order("position DESC, id DESC").first
        record(record_) if record_
      end

      def read(spec)
        stream = read_scope(spec)
        if spec.batched?
          spec.time_sort_by ? offset_limit_batch_reader(spec, stream) : monotonic_id_batch_reader(spec, stream)
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

      def streams_of(event_id)
        @stream_klass.where(event_id: event_id).pluck(:stream).map { |name| Stream.new(name) }
      end

      def position_in_stream(event_id, stream)
        record = @stream_klass.select("position").where(stream: stream.name).find_by(event_id: event_id)
        raise EventNotFoundInStream if record.nil?
        record.position
      end

      def global_position(event_id)
        record = @event_klass.select("id").find_by(event_id: event_id)
        raise EventNotFound.new(event_id) if record.nil?
        record.id - 1
      end

      def event_in_stream?(event_id, stream)
        @stream_klass.where(event_id: event_id, stream: stream.name).exists?
      end

      def search_streams(stream)
        @stream_klass.where("stream LIKE ?", "#{stream}%").pluck(:stream).uniq
      end

      private

      attr_reader :serializer

      def offset_limit_batch_reader(spec, stream)
        batch_reader = ->(offset, limit) { stream.offset(offset).limit(limit).map(&method(:record)) }
        RubyEventStore::BatchEnumerator.new(spec.batch_size, spec.limit, batch_reader).each
      end

      def monotonic_id_batch_reader(spec, stream)
        batch_reader = ->(offset_id, limit) do
          search_in = spec.stream.global? ? @event_klass.table_name : @stream_klass.table_name
          records =
            if offset_id.nil?
              stream.limit(limit)
            else
              stream.where(start_offset_condition(spec, offset_id, search_in)).limit(limit)
            end
          [records.map(&method(:record)), records.last]
        end
        BatchEnumerator.new(spec.batch_size, spec.limit, batch_reader).each
      end

      def read_scope(spec)
        if spec.stream.global?
          stream = @event_klass
          stream = stream.where(event_id: spec.with_ids) if spec.with_ids?
          stream = stream.where(event_type: spec.with_types) if spec.with_types?
          stream = stream.order(as_at(spec)) if spec.time_sort_by_as_at?
          stream = stream.order(as_of(spec)) if spec.time_sort_by_as_of?
          stream = stream.limit(spec.limit) if spec.limit?
          stream = stream.where(start_condition_in_global_stream(spec)) if spec.start
          stream = stream.where(stop_condition_in_global_stream(spec)) if spec.stop
          stream = stream.where(older_than_condition(spec)) if spec.older_than
          stream = stream.where(older_than_or_equal_condition(spec)) if spec.older_than_or_equal
          stream = stream.where(newer_than_condition(spec)) if spec.newer_than
          stream = stream.where(newer_than_or_equal_condition(spec)) if spec.newer_than_or_equal
          stream.order(id: order(spec))
        else
          stream = @stream_klass.includes(:event).where(stream: spec.stream.name)
          stream = stream.where(event_id: spec.with_ids) if spec.with_ids?
          stream = stream.joins(:event).where(@event_klass.table_name => { event_type: spec.with_types }) if spec.with_types?
          stream = stream.joins(:event).order(as_at(spec)) if spec.time_sort_by_as_at?
          stream = stream.joins(:event).order(as_of(spec)) if spec.time_sort_by_as_of?
          stream = stream.order(id: order(spec))
          stream = stream.limit(spec.limit) if spec.limit?
          stream = stream.where(start_condition(spec)) if spec.start
          stream = stream.where(stop_condition(spec)) if spec.stop
          stream = stream.joins(:event).where(older_than_condition(spec)) if spec.older_than
          stream = stream.joins(:event).where(older_than_or_equal_condition(spec)) if spec.older_than_or_equal
          stream = stream.joins(:event).where(newer_than_condition(spec)) if spec.newer_than
          stream = stream.joins(:event).where(newer_than_or_equal_condition(spec)) if spec.newer_than_or_equal
          stream
        end
      end

      def as_of(spec)
        expr = coalesce(@event_klass.arel_table[:valid_at], @event_klass.arel_table[:created_at])
        spec.forward? ? expr.asc : expr.desc
      end

      def as_at(spec)
        expr = @event_klass.arel_table[:created_at]
        spec.forward? ? expr.asc : expr.desc
      end

      def start_offset_condition(specification, record_id, search_in)
        condition = "#{search_in}.id #{specification.forward? ? ">" : "<"} ?"
        [condition, record_id]
      end

      def stop_offset_condition(specification, record_id, search_in)
        condition = "#{search_in}.id #{specification.forward? ? "<" : ">"} ?"
        [condition, record_id]
      end

      def start_condition(specification)
        start_offset_condition(
          specification,
          @stream_klass.find_by!(event_id: specification.start, stream: specification.stream.name),
          @stream_klass.table_name
        )
      rescue ::ActiveRecord::RecordNotFound
        raise EventNotFound.new(specification.start)
      end

      def stop_condition(specification)
        stop_offset_condition(
          specification,
          @stream_klass.find_by!(event_id: specification.stop, stream: specification.stream.name),
          @stream_klass.table_name
        )
      rescue ::ActiveRecord::RecordNotFound
        raise EventNotFound.new(specification.stop)
      end

      def start_condition_in_global_stream(specification)
        start_offset_condition(
          specification,
          @event_klass.find_by!(event_id: specification.start),
          @event_klass.table_name
        )
      rescue ::ActiveRecord::RecordNotFound
        raise EventNotFound.new(specification.start)
      end

      def stop_condition_in_global_stream(specification)
        stop_offset_condition(
          specification,
          @event_klass.find_by!(event_id: specification.stop),
          @event_klass.table_name
        )
      rescue ::ActiveRecord::RecordNotFound
        raise EventNotFound.new(specification.stop)
      end

      def coalesce(*exprs)
        Arel::Nodes::NamedFunction.new "COALESCE", exprs
      end

      def time_comparison_field(specification)
        if specification.time_sort_by_as_of?
          coalesce(@event_klass.arel_table[:valid_at], @event_klass.arel_table[:created_at])
        else
          @event_klass.arel_table[:created_at]
        end
      end

      def older_than_condition(specification)
        time_comparison_field(specification).lt(specification.older_than)
      end

      def older_than_or_equal_condition(specification)
        time_comparison_field(specification).lteq(specification.older_than_or_equal)
      end

      def newer_than_condition(specification)
        time_comparison_field(specification).gt(specification.newer_than)
      end

      def newer_than_or_equal_condition(specification)
        time_comparison_field(specification).gteq(specification.newer_than_or_equal)
      end

      def order(spec)
        spec.forward? ? "ASC" : "DESC"
      end

      def record(record)
        record = record.event if @stream_klass === record

        SerializedRecord
          .new(
            event_id: record.event_id,
            metadata: record.metadata,
            data: record.data,
            event_type: record.event_type,
            timestamp: record.created_at.iso8601(TIMESTAMP_PRECISION),
            valid_at: (record.valid_at || record.created_at).iso8601(TIMESTAMP_PRECISION)
          )
          .deserialize(serializer)
      end
    end

    private_constant(:EventRepositoryReader)
  end
end
