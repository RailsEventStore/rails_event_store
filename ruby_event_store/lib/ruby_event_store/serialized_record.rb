module RubyEventStore
  class SerializedRecord
    StringsRequired = Class.new(StandardError)
    def initialize(event_id:, data:, metadata:, event_type:)
      raise StringsRequired unless [event_id, data, metadata, event_type].all? { |v| v.instance_of?(String) }
      @event_id   = event_id
      @data       = data
      @metadata   = metadata
      @event_type = event_type
      freeze
    end

    attr_reader :event_id, :data, :metadata, :event_type
  end
end
