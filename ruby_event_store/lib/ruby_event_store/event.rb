# frozen_string_literal: true

require "securerandom"

module RubyEventStore
  # Data structure representing an event
  class Event
    # Instantiates a new event
    #
    # @param event_id [String] event id
    # @param data [Hash] event data which belong to your application domain
    # @param metadata [Hash] event metadata which are technical and not
    #   part of your domain such as remote_ip, request_id, correlation_id,
    #   causation_id etc.
    # @return [Event]
    def initialize(event_id: SecureRandom.uuid, metadata: nil, data: {})
      @event_id = event_id.to_s
      @metadata = Metadata.new(metadata.to_h)
      @data = data
    end

    attr_reader :event_id, :metadata, :data

    # Event id
    # @return [String]
    def message_id
      event_id
    end

    # Type of event. Used when matching with subscribed handlers.
    # @return [String]
    def event_type
      metadata[:event_type] || self.class.name
    end

    # Timestamp from metadata
    #
    # @return [Time, nil]
    def timestamp
      metadata[:timestamp]
    end

    # Validity time from metadata
    #
    # @return [Time, nil]
    def valid_at
      metadata[:valid_at]
    end

    # Two events are equal if:
    # * they are of the same class
    # * have identical event type
    # * have identical event id
    # * have identical data (verified with eql? method)
    #
    # @param other_event [Event, Object] object to compare
    #
    # Event equality ignores metadata!
    # @return [TrueClass, FalseClass]
    def ==(other_event)
      other_event.instance_of?(self.class) && other_event.event_type.eql?(event_type) &&
        other_event.event_id.eql?(event_id) && other_event.data.eql?(data)
    end

    # Generates a Fixnum hash value for this object. This function
    # have the property that a.eql?(b) implies a.hash == b.hash.
    #
    # The hash value is used along with eql? by the Hash class to
    # determine if two objects reference the same hash key.
    #
    # This hash is based on
    # * class
    # * event_id
    # * data
    def hash
      # We don't use metadata because == does not use metadata
      [event_type, event_id, data].hash ^ self.class.hash
    end

    # Reads correlation_id from metadata.
    # {http://railseventstore.org/docs/correlation_causation/ Find out more}
    #
    # @return [String, nil]
    def correlation_id
      metadata[:correlation_id]
    end

    # Sets correlation_id in metadata.
    # {http://railseventstore.org/docs/correlation_causation/ Find out more}
    #
    # @param val [String]
    # @return [String]
    def correlation_id=(val)
      metadata[:correlation_id] = val
    end

    # Reads causation_id from metadata.
    # {http://railseventstore.org/docs/correlation_causation/ Find out more}
    #
    # @return [String, nil]
    def causation_id
      metadata[:causation_id]
    end

    # Sets causation_id= in metadata.
    # {http://railseventstore.org/docs/correlation_causation/ Find out more}
    #
    # @param val [String]
    # @return [String]
    def causation_id=(val)
      metadata[:causation_id] = val
    end

    # Sets correlation_id and causation_id in metadata based
    # on correlation_id and message_id of the provided message.
    # {http://railseventstore.org/docs/correlation_causation/ Find out more}
    #
    # @param other_message [Event, command] message to correlate with. Most likely an event or a command. Must respond to correlation_id and message_id.
    # @return [String] set causation_id
    def correlate_with(other_message)
      self.correlation_id = other_message.correlation_id || other_message.message_id
      self.causation_id = other_message.message_id
      self
    end

    # Returns a hash of the name/value pairs for the given event attributes.
    #
    # @param attributes [Array] attributes to deconstruct
    # @return [Hash] deconstructed event
    def deconstruct_keys(attributes)
      {
        causation_id: causation_id,
        correlation_id: correlation_id,
        data: data,
        event_id: event_id,
        event_type: event_type,
        metadata: metadata.to_h
      }.slice(*attributes)
    end

    alias_method :eql?, :==
  end
end
