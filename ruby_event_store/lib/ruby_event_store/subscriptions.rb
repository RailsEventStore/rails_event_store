# frozen_string_literal: true

require 'concurrent'

module RubyEventStore
  class Subscriptions
    def initialize(store: InMemorySubscriptionsStore.new,
                   thread_store_factory: -> { InMemorySubscriptionsStore.new })
      @store = store
      @thread = ThreadSubscriptions.new(thread_store_factory)
    end

    def add_subscription(subscriber, event_types)
      Subscription.new(subscriber, event_types, store: store)
    end

    def add_global_subscription(subscriber)
      Subscription.new(subscriber, store: store)
    end

    def add_thread_subscription(subscriber, event_types)
      thread.add(subscriber, event_types)
    end

    def add_thread_global_subscription(subscriber)
      thread.add(subscriber, [GLOBAL_SUBSCRIPTION])
    end

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
