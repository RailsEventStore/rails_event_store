# frozen_string_literal: true

require 'concurrent'

module RubyEventStore
  class Subscriptions
    def initialize(store: InMemorySubscriptionsStore.new, temp_store_class: InMemorySubscriptionsStore)
      @store = store
      @thread = ThreadSubscriptions.new(temp_store_class)
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
      def initialize(store_klass)
        @store = build_store(store_klass)
      end

      def add(subscriber, event_types)
        Subscription.new(subscriber, event_types, store: store.value)
      end

      def all_for(event_type)
        store.value.all_for(event_type)
      end

      private
      attr_reader :store

      def build_store(klass)
        var = Concurrent::ThreadLocalVar.new(klass.new)
        var.value = klass.new
        var
      end
    end
  end
end
