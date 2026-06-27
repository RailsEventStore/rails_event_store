# frozen_string_literal: true

module RubyEventStore
  Record = Data.define(:event_id, :data, :metadata, :event_type, :timestamp, :valid_at) do
    def initialize(event_id:, data:, metadata:, event_type:, timestamp:, valid_at:)
      raise StringsRequired unless [event_id, event_type].all? { |v| v.instance_of?(String) }
      @serialized_records = {}
      super
    end

    def serialize(serializer)
      @serialized_records[serializer] ||= SerializedRecord.new(
        event_id: event_id,
        event_type: event_type,
        data: serializer.dump(data),
        metadata: serializer.dump(metadata),
        timestamp: timestamp.iso8601(TIMESTAMP_PRECISION),
        valid_at: valid_at.iso8601(TIMESTAMP_PRECISION),
      )
    end
  end
  Record::StringsRequired = StringsRequired
end
