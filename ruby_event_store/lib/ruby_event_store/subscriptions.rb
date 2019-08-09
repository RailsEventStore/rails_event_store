# frozen_string_literal: true

require 'concurrent'

module RubyEventStore
  class Subscriptions
    def initialize(local_store: Store, global_store: GlobalStore)
      @local  = LocalSubscriptions.new(local_store.new)
      @global = GlobalSubscriptions.new(global_store.new)
      @thread = ThreadSubscriptions.new(local_store, global_store)
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

    class Store
      def initialize
        @subscriptions = Hash.new {|hsh, key| hsh[key] = [] }
      end

      def add(type, subscription)
        @subscriptions[type.to_s] << subscription
      end

      def delete(type, subscription)
        @subscriptions.fetch(type.to_s).delete(subscription)
      end

      def all_for(event_type)
        @subscriptions[event_type]
      end

      def value
        self
      end
    end

    class GlobalStore
      def initialize
        @subscriptions = []
      end

      def add(subscription)
        @subscriptions << subscription
      end

      def delete(subscription)
        @subscriptions.delete(subscription)
      end

      def all
        @subscriptions
      end

      def value
        self
      end
    end

    class ThreadSubscriptions
      def initialize(local_store, global_store)
        @local  = LocalSubscriptions.new(build_store(local_store))
        @global = GlobalSubscriptions.new(build_store(global_store))
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
        Subscription.new(subscription, event_types, @store.value)
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
        GlobalSubscription.new(subscription, @store.value)
      end

      def all_for(_event_type)
        @store.value.all
      end
    end
  end
end
