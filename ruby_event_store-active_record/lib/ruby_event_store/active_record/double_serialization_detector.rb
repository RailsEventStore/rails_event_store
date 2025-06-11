# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    module DoubleSerializationDetector
      def unwrap(column_name, deserialized_payload)
        if String === deserialized_payload && deserialized_payload.start_with?("\{")
          warn "Double serialization of #{column_name} column detected"
          serializer.load(deserialized_payload)
        else
          deserialized_payload
        end
      end

      def record(record)
        record_ = super(record)

        Record.new(
          event_id: record_.event_id,
          metadata: unwrap("metadata", record_.metadata),
          data: unwrap("data", record_.data),
          event_type: record_.event_type,
          timestamp: record_.timestamp,
          valid_at: record_.valid_at,
        )
      end
    end
  end
end
