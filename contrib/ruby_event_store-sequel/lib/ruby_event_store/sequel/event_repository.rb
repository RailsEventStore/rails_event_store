# frozen_string_literal: true

module RubyEventStore
  module Sequel
    class EventRepository
      def initialize(serializer:)
        @serializer = serializer
        @db = ::Sequel.sqlite
        @db.create_table(:event_store_events) do
          primary_key :id
          String :event_id
          String :event_type
          File :data
          File :metadata
          Time :created_at
          Time :valid_at
        end
      end

      def append_to_stream(records, stream, expected_version)
        records.map do |r|
          sr = r.serialize(@serializer)

          @db[:event_store_events].insert(
            event_id: sr.event_id,
            event_type: sr.event_type,
            data: sr.data,
            metadata: sr.metadata,
            created_at: sr.timestamp,
            valid_at: sr.valid_at
          )
        end
        self
      end

      def link_to_stream(event_ids, stream, expected_version)
        self
      end

      def position_in_stream(event_id, stream)
      end

      def global_position(event_id)
      end

      def event_in_stream?(event_id, stream)
      end

      def delete_stream(stream)
      end

      def has_event?(event_id)
      end

      def last_stream_event(stream)
      end

      def read(specification)
        @db[:event_store_events].all.map do |h|
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
