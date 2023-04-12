# frozen_string_literal: true

module RubyEventStore
  module Sequel
    class EventRepository
      def initialize(serializer:)
        @serializer = serializer
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
            )
          end
        end
        self
      rescue ::Sequel::UniqueConstraintViolation
        raise WrongExpectedEventVersion
      end

      def link_to_stream(event_ids, stream, expected_version)
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
      rescue ::Sequel::UniqueConstraintViolation
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
          dataset = dataset.limit(specification.limit) if specification.limit?
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
        end
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
