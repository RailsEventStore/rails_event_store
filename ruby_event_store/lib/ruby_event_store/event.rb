require 'securerandom'

module RubyEventStore
  class Event

    def initialize(event_id: SecureRandom.uuid, metadata: {}, **data)
      data.each do |key, value|
        singleton_class.__send__(:define_method, key) { value }
      end

      @event_id = event_id.to_s
      @metadata = metadata
      @data     = data
      @metadata[:timestamp] ||= Time.now.utc
    end
    attr_reader :event_id, :metadata, :data

    def to_h
      {
          event_id:   event_id,
          metadata:   metadata,
          data:       data
      }
    end

    def timestamp
      metadata[:timestamp]
    end

    def ==(other_event)
      other_event.instance_of?(self.class) && other_event.to_h.eql?(to_h)
    end

    alias_method :eql?, :==
  end
end
