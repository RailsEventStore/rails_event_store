# frozen_string_literal: true

require 'concurrent'

module RubyEventStore
  # Subscriptions management - handles either defined subscriptions & temporary (thread) subscriptions
  class Subscriptions
    # Instatiates a new subscriptions provider
    #
    # @param store - subscriptions store, default: [InMemorySubscriptionsStore] instance
    # @param thread_store_factory [Proc, Lamnda, callable Object] a factory to create subscriptions store
    # @return [Subscriptions]
    def initialize(
      store: InMemorySubscriptionsStore.new,
      thread_store_factory: -> { InMemorySubscriptionsStore.new }
    )
      @store = store
      @thread = ThreadSubscriptions.new(thread_store_factory)
    end

    # Creates a subscription for subscriber & given event types
    #
    # @param subscriber [Proc, Lambda, callable Object] to handle domain event
    # @param event_types [Array<String, Class>] list of domain event types to subscribe for
    # @return [Subscription]
    def add_subscription(subscriber, event_types)
      Subscription.new(subscriber, event_types, store: store)
    end

    # Creates a global subscription for subscriber
    #
    # @param subscriber [Proc, Lambda, callable Object] to handle any domain event
    # @return [Subscription]
    def add_global_subscription(subscriber)
      Subscription.new(subscriber, store: store)
    end

    # Creates a temporary subscription for subscriber & given event types
    #
    # @param subscriber [Proc, Lambda, callable Object] to handle domain event
    # @param event_types [Array<String, Class>] list of domain event types to subscribe for
    # @return [Subscription]
    def add_thread_subscription(subscriber, event_types)
      thread.add(subscriber, event_types)
    end

    # Creates a temporary global subscription for subscriber
    #
    # @param subscriber [Proc, Lambda, callable Object] to handle domain event
    # @return [Subscription]
    def add_thread_global_subscription(subscriber)
      thread.add(subscriber, [GLOBAL_SUBSCRIPTION])
    end

    # Gets all subscriptions for given event type
    #
    # @param event_type [String, Class] domain event type
    # @return [Array<Subscription>]
    def all_for(event_type)
      [event_type, GLOBAL_SUBSCRIPTION].map do |type|
        [store, thread].map { |r| r.all_for(type) }
      end.flatten
    end

    private
    attr_reader :store, :thread

    class ThreadSubscriptions
      def initialize(store_factory)
        @store = build_store(store_factory)
      end

      def add(subscriber, event_types)
        Subscription.new(subscriber, event_types, store: store.value)
      end

      def all_for(event_type)
        store.value.all_for(event_type)
      end

      private
      attr_reader :store

      def build_store(store_factory)
        var = Concurrent::ThreadLocalVar.new(store_factory.call)
        var.value = store_factory.call
        var
      end
    end
  end
end
