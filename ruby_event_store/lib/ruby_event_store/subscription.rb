# frozen_string_literal: true

module RubyEventStore
  # Subsciption object
  class Subscription
    # Instantiates a new subscription
    #
    # @param subscriber - a callable object / class or lambda execured when subscription is triggered
    # @param event_types [Array<Class, String>] - types of events for which subscription should be triggered. When no event types are given a global subscription is created.
    # @param store - subscription store where subscription is persisted. When subscription store is nil a subscription is not persisted (usefull in tests).
    #
    # @return [Subscription]
    def initialize(subscriber, event_types = [GLOBAL_SUBSCRIPTION], store: nil)
      raise SubscriberNotExist, 'subscriber must exists' unless subscriber

      @subscriber = subscriber
      @event_types = event_types
      @store = store
      event_types.each{ |type| @store.add(self, type) } if persisted?
    end

    # Triggers the defined subscribed
    # When subscriber is a [Class] a new subscriber's class object is created
    #
    # @param event - [Event] to pass to subscriber
    def call(event)
      (Class === subscriber ? subscriber.new : subscriber).call(event)
    end

    # Unsubscribe subscription for all defined event types
    # No-op when subscription store is nil
    def unsubscribe
      event_types.each{ |type| @store.delete(self, type) } if persisted?
    end

    # Return true is this is a global subscription
    # Global subscriptions are triggered by each domain event
    #
    # @return [TrueClass, FalseClass]
    def global?
      event_types.include?(GLOBAL_SUBSCRIPTION)
    end

    # Return true is this subscription is stored
    # It will return true also after subscription is unsubscribed
    #
    # @return [TrueClass, FalseClass]
    def persisted?
      !@store.nil?
    end

    def inspect
      "#<#{self.class}:0x#{__id__.to_s(16)}>\n  - #{ !event_types.eql?([GLOBAL_SUBSCRIPTION]) ? "event types: #{event_types}" : "global subscription"}\n  - subscriber: #{subscriber.inspect}"
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
        other.subscriber.equal?(subscriber)
    end
    alias_method :eql?, :==

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
    # * subscriber object id
    def hash
      [
        self.class,
        event_types,
        subscriber,
      ].hash ^ BIG_VALUE
    end

    attr_reader :subscriber, :event_types
  end
end
