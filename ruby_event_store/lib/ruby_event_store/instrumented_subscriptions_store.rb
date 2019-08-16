# frozen_string_literal: true

module RubyEventStore
  # Instrumented subscriptions store
  class InstrumentedSubscriptionsStore
    # Instantiates a new in memory subscriptions store
    #
    # @return [InstrumentedSubscriptionsStore]
    def initialize(store, instrumentation)
      @store = store
      @instrumentation = instrumentation
    end

    # Stores subscription in the store
    # @param subscription [Subscription] subscription to store
    #
    # @return [self]
    def add(subscription)
      instrumentation.instrument("add.subscription_store.rails_event_store", subscription: subscription) do
        store.add(subscription)
      end
    end

    # Removes subscription from the store
    # @param subscription [Subscription] subscription to remove
    #
    # @return [self]
    def delete(subscription)
      instrumentation.instrument("delete.subscription_store.rails_event_store", subscription: subscription) do
        store.delete(subscription)
      end
    end

    # Gets all subscriptions stored for given event type
    # @param type [String, Class, GLOBAL_SUBSCRIPTION] a type of [Event]
    #        or global subscription for which subscriptions should be returned
    #
    # @return [Array<Subscription>]
    def all_for(type)
      store.all_for(type)
    end

    # Gets all subscriptions stored
    #
    # @return [Array<Subscription>]
    def all
      store.all
    end

    private
    attr_reader :instrumentation, :store
  end
end
