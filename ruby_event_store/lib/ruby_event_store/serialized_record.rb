# frozen_string_literal: true

module RubyEventStore
  SerializedRecord = Data.define(:event_id, :data, :metadata, :event_type, :timestamp, :valid_at) do
    def initialize(event_id:, data:, metadata:, event_type:, timestamp:, valid_at:)
      raise StringsRequired unless [event_id, event_type].all? { |v| v.instance_of?(String) }
      super
    end

    def deserialize(serializer)
      Record.new(
        event_id: event_id,
        event_type: event_type,
        data: serializer.load(data),
        metadata: serializer.load(metadata),
        timestamp: Time.iso8601(timestamp),
        valid_at: Time.iso8601(valid_at),
      )
    end
  end
  SerializedRecord::StringsRequired = StringsRequired
end
