# frozen_string_literal: true

module RubyEventStore
  module Sequel
    class EventRepository
      def initialize(serializer:)
        @serializer = serializer
        @index_violation_detector = IndexViolationDetector.new("event_store_events", "event_store_events_in_streams")
        @db = ::Sequel.connect(ENV.fetch("DATABASE_URL"))
        @db.timezone = :utc
        @db.loggers << Logger.new(STDOUT) if ENV.has_key?("VERBOSE")
        @db.create_table(:event_store_events) do
          primary_key :id
          column :event_id, "varchar(36)", null: false
          column :event_type, "varchar", null: false
          column :data, "blob", null: false
          column :metadata, "blob"
          column :created_at, "datetime(6)", null: false
          column :valid_at, "datetime(6)"

          index :event_id, unique: true
        end
        @db.create_table(:event_store_events_in_streams) do
          primary_key :id
          column :event_id, "varchar(36)", null: false
          column :stream, "varchar", null: false
          column :position, "integer"
          column :created_at, "datetime(6)", null: false

          index %i[stream position], unique: true
          index %i[stream event_id], unique: true
        end
      end

      attr_reader :index_violation_detector

      def append_to_stream(records, stream, expected_version)
        resolved_version =
          expected_version.resolve_for(
            stream,
            ->(stream) do
              @db[:event_store_events_in_streams]
                .select(:position)
                .where(stream: stream.name)
                .order(:position)
                .last
                &.fetch(:position)
            end
          )

        @db.transaction do
          records.map.with_index do |r, index|
            sr = r.serialize(@serializer)

            @db[:event_store_events].insert(
              event_id: sr.event_id,
              event_type: sr.event_type,
              data: sr.data,
              metadata: sr.metadata,
              created_at: r.timestamp,
              valid_at: r.valid_at
            )
            @db[:event_store_events_in_streams].insert(
              event_id: sr.event_id,
              stream: stream.name,
              created_at: Time.now.utc,
              position: resolved_version ? resolved_version + index + 1 : nil
            ) unless stream.global?
          end
        end
        self
      rescue ::Sequel::UniqueConstraintViolation => ex
        raise EventDuplicatedInStream if index_violation_detector.detect(ex.message)
        raise WrongExpectedEventVersion
      end

      def link_to_stream(event_ids, stream, expected_version)

        (event_ids - @db[:event_store_events].select(:event_id).where(event_id: event_ids).map { |e| e[:event_id] }).each do |id|
          raise EventNotFound.new(id)
        end

        resolved_version =
          expected_version.resolve_for(
            stream,
            ->(stream) do
              @db[:event_store_events_in_streams]
                .select(:position)
                .where(stream: stream.name)
                .order(:position)
                .last
                &.fetch(:position)
            end
          )

        @db.transaction do
          event_ids.map.with_index do |event_id, index|
            @db[:event_store_events_in_streams].insert(
              event_id: event_id,
              stream: stream.name,
              created_at: Time.now.utc,
              position: resolved_version ? resolved_version + index + 1 : nil
            )
          end
        end
        self
      rescue ::Sequel::UniqueConstraintViolation => ex
        raise EventDuplicatedInStream if index_violation_detector.detect(ex.message)
        raise WrongExpectedEventVersion
      end

      def position_in_stream(event_id, stream)
      end

      def global_position(event_id)
      end

      def event_in_stream?(event_id, stream)
      end

      def delete_stream(stream)
        @db[:event_store_events_in_streams].where(stream: stream.name).delete
      end

      def has_event?(event_id)
        @db[:event_store_events].where(event_id: event_id).any?
      end

      def last_stream_event(stream)
        row =
          @db[:event_store_events_in_streams]
            .where(stream: stream.name)
            .order(:position, :id)
            .last
        return row if row.nil?
        event = @db[:event_store_events].where(event_id: row[:event_id]).first
        SerializedRecord.new(
          event_id: event[:event_id],
          event_type: event[:event_type],
          data: event[:data],
          metadata: event[:metadata],
          timestamp: event[:created_at].iso8601(TIMESTAMP_PRECISION),
          valid_at: event[:valid_at].iso8601(TIMESTAMP_PRECISION)
        ).deserialize(@serializer)
      end

      def read(specification)
        if specification.batched?
          stream = read_(specification)
          batch_reader = ->(offset, limit) { stream.offset(offset).limit(limit).map(&method(:record)) }
        RubyEventStore::BatchEnumerator.new(specification.batch_size, specification.limit, batch_reader).each
        elsif specification.first?
          record_ = read_(specification).first
          record(record_) if record_
        elsif specification.last?
          record_ = read_(specification).last
          record(record_) if record_
        else
            read_(specification).map do |h|
            record(h)
          end.each
        end
      end

      def read_(specification)
        if specification.stream.global?
          dataset =
            @db[:event_store_events].select(
              :event_id,
              :event_type,
              :data,
              :metadata,
              :created_at,
              :valid_at
            )
            .order(:id)

            if specification.with_ids?
              dataset = dataset.where(event_id: specification.with_ids)
            end

            if specification.with_types?
              dataset = dataset.where(event_type: specification.with_types)
            end


          if specification.start
            id = @db[:event_store_events].select(:id).where(event_id: specification.start).first[:id]
            condition = "event_store_events.id #{specification.forward? ? ">" : "<"} ?"

            dataset = dataset.where(::Sequel.lit(condition, id))
          end

          if specification.stop
            id = @db[:event_store_events].select(:id).where(event_id: specification.stop).first[:id]
            condition = "event_store_events.id #{specification.forward? ? "<" : ">"} ?"

            dataset = dataset.where(::Sequel.lit(condition, id))
          end

          if specification.older_than
            dataset = dataset.where(::Sequel.lit("event_store_events.created_at < ?", specification.older_than))
          end


          dataset = dataset.limit(specification.limit) if specification.limit?
          dataset = dataset.order(::Sequel[:event_store_events][:id]).reverse if specification.backward?

          dataset
        else
          dataset =
            @db[:event_store_events]
              .join(:event_store_events_in_streams, event_id: :event_id)
              .select(
                ::Sequel[:event_store_events][:event_id],
                :event_type,
                :data,
                :metadata,
                ::Sequel[:event_store_events][:created_at],
                :valid_at
              )
              .where(stream: specification.stream.name)
              .order(::Sequel[:event_store_events_in_streams][:id])

            if specification.with_types?
              dataset = dataset.where(event_type: specification.with_types)
            end


          if specification.with_ids?
             dataset = dataset.where(::Sequel[:event_store_events][:event_id] => specification.with_ids)
          end


          if specification.start
            id = @db[:event_store_events_in_streams].select(:id).where(event_id: specification.start, stream: specification.stream.name).first[:id]
            condition = "event_store_events_in_streams.id #{specification.forward? ? ">" : "<"} ?"

            dataset = dataset.where(::Sequel.lit(condition, id))
          end

          if specification.stop
            id = @db[:event_store_events_in_streams].select(:id).where(event_id: specification.stop, stream: specification.stream.name).first[:id]
            condition = "event_store_events_in_streams.id #{specification.forward? ? "<" : ">"} ?"

            dataset = dataset.where(::Sequel.lit(condition, id))
          end

          if specification.older_than
            dataset = dataset.where(::Sequel.lit("event_store_events.created_at < ?", specification.older_than))
          end

          dataset = dataset.limit(specification.limit) if specification.limit?
          dataset = dataset.order(::Sequel[:event_store_events_in_streams][:id]).reverse if specification.backward?

          dataset
        end
      end

      def count(specification)
        read_(specification).count
      end

      def update_messages(records)
      end

      def streams_of(event_id)
        @db[:event_store_events_in_streams].where(event_id: event_id)
          .map do |h|
            Stream.new(h[:stream])
          end
      end

      def record(h)
         SerializedRecord.new(
            event_id: h[:event_id],
            event_type: h[:event_type],
            data: h[:data],
            metadata: h[:metadata],
            timestamp: h[:created_at].iso8601(TIMESTAMP_PRECISION),
            valid_at: h[:valid_at].iso8601(TIMESTAMP_PRECISION)
          ).deserialize(@serializer)
      end
    end
  end
end
