# frozen_string_literal: true

require "concurrent"

module RubyEventStore
  class Subscriptions
    def initialize
      @local = LocalSubscriptions.new
      @global = GlobalSubscriptions.new
      @thread = ThreadSubscriptions.new
    end

    def add_subscription(subscriber, topics)
      local.add(subscriber, topics)
    end

    def add_global_subscription(subscriber)
      global.add(subscriber)
    end

    def add_thread_subscription(subscriber, topics)
      thread.local.add(subscriber, topics)
    end

    def add_thread_global_subscription(subscriber)
      thread.global.add(subscriber)
    end

    def all_for(topic)
      [local, global, thread].map { |r| r.all_for(topic) }.reduce(&:+)
    end

    private

    attr_reader :local, :global, :thread

    class ThreadSubscriptions
      def initialize
        @local = ThreadLocalSubscriptions.new
        @global = ThreadGlobalSubscriptions.new
      end
      attr_reader :local, :global

      def all_for(topic)
        [global, local].map { |r| r.all_for(topic) }.reduce(&:+)
      end
    end

    class LocalSubscriptions
      def initialize
        @subscriptions = Hash.new { |hsh, key| hsh[key] = [] }
      end

      def add(subscription, topics)
        topics.each { |topic| @subscriptions[topic] << subscription }
        -> { topics.each { |topic| @subscriptions.fetch(topic).delete(subscription) } }
      end

      def all_for(topic)
        @subscriptions[topic]
      end
    end

    class GlobalSubscriptions
      def initialize
        @subscriptions = []
      end

      def add(subscription)
        @subscriptions << subscription
        -> { @subscriptions.delete(subscription) }
      end

      def all_for(_topic)
        @subscriptions
      end
    end

    class ThreadLocalSubscriptions
      def initialize
        @subscriptions = Concurrent::ThreadLocalVar.new { Hash.new { |hsh, key| hsh[key] = [] } }
      end

      def add(subscription, topics)
        topics.each { |topic| @subscriptions.value[topic] << subscription }
        -> { topics.each { |topic| @subscriptions.value.fetch(topic).delete(subscription) } }
      end

      def all_for(topic)
        @subscriptions.value[topic]
      end
    end

    class ThreadGlobalSubscriptions
      def initialize
        @subscriptions = Concurrent::ThreadLocalVar.new([])
      end

      def add(subscription)
        @subscriptions.value += [subscription]
        -> { @subscriptions.value -= [subscription] }
      end

      def all_for(_topic)
        @subscriptions.value
      end
    end
  end
end
