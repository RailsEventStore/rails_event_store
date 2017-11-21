module RubyEventStore
  class SerializedRecord
    def initialize(id:, data:, metadata:, event_type:)
      @id         = id
      @data       = data
      @metadata   = metadata
      @event_type = event_type
      freeze
    end

    attr_reader :id, :data, :metadata, :event_type
  end
end
