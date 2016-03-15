require 'securerandom'

module RubyEventStore
  class Event

    def initialize(**args)
      attributes(args).each do |key, value|
        singleton_class.__send__(:define_method, key) { value }
      end

      @event_id   = (args[:event_id]  || generate_id).to_s
      @metadata   = args[:metadata]   || {}
      @data       = attributes(args)
      @metadata[:timestamp] ||= Time.now.utc
    end
    attr_reader :event_id, :metadata, :data

    def event_type
      self.class
    end

    def to_h
      {
          event_type: event_type.name,
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

    private

    def attributes(args)
      args.reject { |k| [:event_id, :metadata].include? k }
    end

    def generate_id
      SecureRandom.uuid
    end
  end
end
