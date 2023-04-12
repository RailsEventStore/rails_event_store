# frozen_string_literal: true

module RubyEventStore
  module Sequel
    class EventRepository
      def initialize(serializer:)
        @serializer = serializer
        @index_violation_detector = IndexViolationDetector.new("event_store_events", "event_store_events_in_streams")
        @db = ::Sequel.sqlite
        @db.loggers << Logger.new(STDOUT) if ENV.has_key?("VERBOSE")
        @db.create_table(:event_store_events) do
          primary_key :id
          String :event_id
          String :event_type
          File :data
          File :metadata
          Time :created_at
          Time :valid_at

          index :event_id, unique: true
        end
        @db.create_table(:event_store_events_in_streams) do
          primary_key :id
          String :event_id
          String :stream
          Integer :position
          Time :created_at

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
              created_at: sr.timestamp,
              valid_at: sr.valid_at
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

          dataset = dataset.limit(specification.limit) if specification.limit?
          dataset = dataset.order(::Sequel[:event_store_events_in_streams][:id]).reverse if specification.backward?

          dataset
        end

        dataset.map do |h|
          SerializedRecord.new(
            event_id: h[:event_id],
            event_type: h[:event_type],
            data: h[:data],
            metadata: h[:metadata],
            timestamp: h[:created_at].iso8601(TIMESTAMP_PRECISION),
            valid_at: h[:valid_at].iso8601(TIMESTAMP_PRECISION)
          ).deserialize(@serializer)
        end.each
      end

      def count(specification)
      end

      def update_messages(records)
      end

      def streams_of(event_id)
      end
    end
  end
end
