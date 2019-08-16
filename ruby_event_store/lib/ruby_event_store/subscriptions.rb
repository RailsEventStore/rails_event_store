# frozen_string_literal: true

require 'concurrent'

module RubyEventStore
  class Subscriptions
    def initialize(store: InMemorySubscriptionsStore.new, temp_store_class: InMemorySubscriptionsStore)
      @local  = LocalSubscriptions.new(store)
      @global = GlobalSubscriptions.new(store)
      @thread = ThreadSubscriptions.new(temp_store_class)
    end

    def add_subscription(subscriber, event_types)
      local.add(subscriber, event_types)
    end

    def add_global_subscription(subscriber)
      global.add(subscriber)
    end

    def add_thread_subscription(subscriber, event_types)
      thread.local.add(subscriber, event_types)
    end

    def add_thread_global_subscription(subscriber)
      thread.global.add(subscriber)
    end

    def all_for(event_type)
      [local, global, thread].map{|r| r.all_for(event_type)}.reduce(&:+)
    end

    private
    attr_reader :local, :global, :thread

    class ThreadSubscriptions
      def initialize(store_klass)
        @local  = LocalSubscriptions.new(build_store(store_klass))
        @global = GlobalSubscriptions.new(build_store(store_klass))
      end
      attr_reader :local, :global

      def all_for(event_type)
        [global, local].map{|r| r.all_for(event_type)}.reduce(&:+)
      end

      private

      def build_store(klass)
        var = Concurrent::ThreadLocalVar.new(klass.new)
        var.value = klass.new
        var
      end
    end

    class LocalSubscriptions
      def initialize(store)
        @store = store
      end

      def add(subscription, event_types)
        Subscription.new(subscription, event_types, store: @store.value)
      end

      def all_for(event_type)
        @store.value.all_for(event_type)
      end
    end

    class GlobalSubscriptions
      def initialize(store)
        @store = store
      end

      def add(subscription)
        GlobalSubscription.new(subscription, store: @store.value)
      end

      def all_for(_event_type)
        @store.value.all_global
      end
    end
  end
end
