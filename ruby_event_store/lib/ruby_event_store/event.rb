require 'securerandom'

module RubyEventStore
  class Event
    def initialize(event_id: SecureRandom.uuid, metadata: nil, data: nil)
      @event_id = event_id.to_s
      @metadata = metadata.to_h
      @data     = data.to_h
    end
    attr_reader :event_id, :metadata, :data

    def type
      self.class.name
    end

    def to_h
      {
          event_id:   event_id,
          metadata:   metadata,
          data:       data,
          type:       type,
      }
    end

    def timestamp
      metadata[:timestamp]
    end

    def ==(other_event)
      other_event.instance_of?(self.class) &&
        other_event.event_id.eql?(event_id) &&
        other_event.data.eql?(data)
    end

    BIG_VALUE = 0b111111100100000010010010110011101011000101010101001100100110000

    # We don't use metadata because == does not use metadata
    def hash
      [
        self.class,
        event_id,
        data
      ].hash ^ BIG_VALUE
    end

    alias_method :eql?, :==
  end
end