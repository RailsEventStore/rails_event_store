# frozen_string_literal: true

module RubyEventStore
  # In memory subscriptions store
  class InMemorySubscriptionsStore
    # Instantiates a new in memory subscriptions store
    #
    # @return [InMemorySubscriptionsStore]
    def initialize
      @subscriptions = Hash.new { |hsh, key| hsh[key] = [] }
    end

    # Stores subscription in the store
    # @param subscription [Subscription] subscription to store
    # @param type [String, Class, GLOBAL_SUBSCRIPTION] a type of [Event]
    #        or global subscription for for which subscription should be stored
    #
    # @return [self]
    def add(subscription, type = GLOBAL_SUBSCRIPTION)
      @subscriptions[type.to_s] << subscription
      self
    end

    # Removed subscription from the store
    # @param subscription [Subscription] subscription to remove
    # @param type [String, Class, GLOBAL_SUBSCRIPTION] a type of [Event]
    #        or global subscription for for which subscription should be removed
    #
    # @return [self]
    def delete(subscription, type = GLOBAL_SUBSCRIPTION)
      @subscriptions.fetch(type.to_s).delete(subscription)
      self
    end

    # Gets all subscriptions stored for given event type
    # @param type [String, Class, GLOBAL_SUBSCRIPTION] a type of [Event]
    #        or global subscription for which subscriptions should be returned
    #
    # @return [Array<Subscription>]
    def all_for(type)
      @subscriptions[type.to_s]
    end

    # Gets all subscriptions stored
    #
    # @return [Array<Subscription>]
    def all
      @subscriptions.values.flatten.uniq
    end

    # Gets this instance of subscription store
    # Required for internal implementation of thread subscriptions
    #
    # @return [self]
    def value
      self
    end
  end
end
