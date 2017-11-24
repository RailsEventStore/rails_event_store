module RubyEventStore
  class SerializedRecord
    def initialize(event_id:, data:, metadata:, event_type:)
      @event_id   = event_id
      @data       = data
      @metadata   = metadata
      @event_type = event_type
      freeze
    end

    attr_reader :event_id, :data, :metadata, :event_type
  end
end
