module RubyEventStore
  class Subscription
    def initialize(subscriber, event_types = [GLOBAL_SUBSCRIPTION], store: nil)
      @subscriber = subscriber
      @event_types = event_types
      @store = store
      event_types.each{ |type| @store.add(self, type) } if @store
    end

    def call(event)
      (Class === subscriber ? subscriber.new : subscriber).call(event)
    end

    def unsubscribe
      event_types.each{ |type| @store.delete(self, type) } if @store
    end

    def inspect
      <<~EOS.strip
          #<#{self.class}:0x#{__id__.to_s(16)}>
            - #{ event_types != [GLOBAL_SUBSCRIPTION] ? "event types: #{event_types.inspect}" : "global subscription"}
            - subscriber: #{subscriber.inspect}
      EOS
    end

    # Two subscriptions are equal if:
    # * they are of the same class
    # * have identical event types
    # * have identical subscriber (verified with eql? method)
    #
    # @param other [Subscription, Object] object to compare
    #
    # Event equality ignores metadata!
    # @return [TrueClass, FalseClass]
    def ==(other)
      other.instance_of?(self.class) &&
        other.event_types.eql?(event_types) &&
        other.subscriber.eql?(subscriber)
    end

    # @private
    BIG_VALUE = 0b11010000100100100101110000000010011110000110101011010001001110

    # Generates a Fixnum hash value for this object. This function
    # have the property that a.eql?(b) implies a.hash == b.hash.
    #
    # The hash value is used along with eql? by the Hash class to
    # determine if two objects reference the same hash key.
    #
    # This hash is based on
    # * class
    # * event types
    # * subscriber objecy id
    def hash
      # We don't use metadata because == does not use metadata
      [
        self.class,
        event_types,
        subscriber.object_id
      ].hash ^ BIG_VALUE
    end

    attr_reader :subscriber, :event_types
  end
end
