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
    #
    # @return [self]
    def add(subscription)
      subscription.subscribed_for.each do |type|
        @subscriptions[type.to_s] << subscription
      end
      self
    end

    # Removed subscription from the store
    # @param subscription [Subscription] subscription to remove
    #
    # @return [self]
    def delete(subscription)
      subscription.subscribed_for.each do |type|
        @subscriptions.fetch(type.to_s).delete(subscription)
      end
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
  end
end
