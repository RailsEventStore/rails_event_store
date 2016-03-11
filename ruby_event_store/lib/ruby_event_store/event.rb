require 'securerandom'

module RubyEventStore
  class Event

    def initialize(**args)
      attributes(args).each do |key, value|
        singleton_class.__send__(:define_method, key) { value }
      end

      @event_type = args[:event_type] || event_name
      @event_id   = (args[:event_id]  || generate_id).to_s
      @metadata   = args[:metadata]   || {}
      @data       = attributes(args)
      @metadata[:timestamp] ||= Time.now.utc
    end
    attr_reader :event_type, :event_id, :metadata, :data

    def to_h
      {
          event_type: event_type,
          event_id:   event_id,
          metadata:   metadata,
          data:       data
      }
    end

    def timestamp
      metadata[:timestamp]
    end

    private

    def attributes(args)
      args.reject { |k| [:event_type, :event_id, :metadata].include? k }
    end

    def generate_id
      SecureRandom.uuid
    end

    def event_name
      self.class.name
    end
  end
end
