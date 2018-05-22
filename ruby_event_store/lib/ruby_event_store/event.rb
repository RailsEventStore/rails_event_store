require 'securerandom'

module RubyEventStore
  class Event
    def initialize(event_id: SecureRandom.uuid, metadata: nil, data: nil)
      @event_id = event_id.to_s
      @metadata = Metadata.new(metadata.to_h)
      @data     = data.to_h
      self.correlation_id ||= @event_id
      self.causation_id   ||= @event_id
    end
    attr_reader :event_id, :metadata, :data

    def type
      self.class.name
    end

    def to_h
      {
          event_id:   event_id,
          metadata:   metadata.to_h,
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

    def correlation_id
      metadata[:correlation_id]
    end

    def correlation_id=(val)
      metadata[:correlation_id] = val
    end

    def causation_id
      metadata[:causation_id]
    end

    def causation_id=(val)
      metadata[:causation_id]=(val)
    end

    def correlate_with(other_message)
      self.correlation_id = other_message.correlation_id || event.event_id
      self.causation_id   = other_message.event_id
    end

    alias_method :eql?, :==
  end
end