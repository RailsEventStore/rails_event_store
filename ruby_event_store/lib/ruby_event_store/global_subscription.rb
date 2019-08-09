module RubyEventStore
  class GlobalSubscription
    def initialize(subscriber, store: nil)
      @subscriber = subscriber
      @store = store
      @store.add(self) if @store
    end

    def call(event)
      (Class === subscriber ? subscriber.new : subscriber).call(event)
    end

    def unsubscribe
      @store.delete(self) if @store
    end

    def inspect
      <<~EOS.strip
          #<#{self.class}:0x#{__id__.to_s(16)}>
            - subscriber: #{subscriber.inspect}
      EOS
    end

    # Two subscriptions are equal if:
    # * they are of the same class
    # * have identical subscriber (verified with eql? method)
    #
    # @param other [GlobalSubscription, Object] object to compare
    #
    # Event equality ignores metadata!
    # @return [TrueClass, FalseClass]
    def ==(other)
      other.instance_of?(self.class) &&
        other.subscriber.eql?(subscriber)
    end

    # @private
    BIG_VALUE = 0b101000101111010111101101010011000101000100000000011011011100110

    # Generates a Fixnum hash value for this object. This function
    # have the property that a.eql?(b) implies a.hash == b.hash.
    #
    # The hash value is used along with eql? by the Hash class to
    # determine if two objects reference the same hash key.
    #
    # This hash is based on
    # * class
    # * subscriber object_id
    def hash
      # We don't use metadata because == does not use metadata
      [
        self.class,
        subscriber.object_id,
      ].hash ^ BIG_VALUE
    end

    attr_reader :subscriber
  end
end
