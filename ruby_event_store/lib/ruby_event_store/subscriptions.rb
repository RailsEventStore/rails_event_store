# frozen_string_literal: true

require 'concurrent'

module RubyEventStore
  class Subscriptions
    def initialize
      @local  = LocalSubscriptions.new
      @global = GlobalSubscriptions.new
      @thread = ThreadSubscriptions.new
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
    end

    class ThreadSubscriptions
      def initialize
        @local  = ThreadLocalSubscriptions.new
        @global = ThreadGlobalSubscriptions.new
      end
      attr_reader :local, :global

      def all_for(event_type)
        [global, local].map{|r| r.all_for(event_type)}.reduce(&:+)
      end
    end

    class LocalSubscriptions
      def initialize
        @store = Store.new
      end

      def add(subscription, event_types)
        Subscription.new(subscription, event_types, @store)
      end

      def all_for(event_type)
        @store.all_for(event_type)
      end
    end

    class GlobalSubscriptions
      def initialize
        @store = GlobalStore.new
      end

      def add(subscription)
        GlobalSubscription.new(subscription, @store)
      end

      def all_for(_event_type)
        @store.all
      end
    end

    class ThreadLocalSubscriptions
      def initialize
        @store = Concurrent::ThreadLocalVar.new(Store.new)
        @store.value = Store.new
      end

      def add(subscription, event_types)
        Subscription.new(subscription, event_types, @store.value)
      end

      def all_for(event_type)
        @store.value.all_for(event_type)
      end
    end

    class ThreadGlobalSubscriptions
      def initialize
        @store = Concurrent::ThreadLocalVar.new(GlobalStore.new)
        @store.value = GlobalStore.new
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
