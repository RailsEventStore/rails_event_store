# frozen_string_literal: true

module RubyEventStore
  class ComposedBroker
    def initialize(*brokers)
      @brokers = brokers
    end

    def call(event, record, topic)
      broker = verified_broker(topic)
      if broker.nil?
        warn "No broker found for topic '#{topic}'. Event #{event.event_id} will not be processed."
      else
        broker.call(event, record, topic)
      end
    end

    def add_subscription(subscriber, topics)
      topics.each do |topic|
        broker = verified_broker(topic)
        raise SubscriptionsNotSupported, "No broker found for topic '#{topic}'." if broker.nil?
        broker.add_subscription(subscriber, topic)
      end
    end

    def add_global_subscription(subscriber)
      broker = verified_broker(nil)
      raise SubscriptionsNotSupported, "No broker found for global subscription." if broker.nil?
      broker.add_global_subscription(subscriber)
    end

    def add_thread_subscription(subscriber, topics)
      topics.each do |topic|
        broker = verified_broker(topic)
        raise SubscriptionsNotSupported, "No broker found for topic '#{topic}'." if broker.nil?
        broker.add_thread_subscription(subscriber, topic)
      end
    end

    def add_thread_global_subscription(subscriber)
      broker = verified_broker(nil)
      raise SubscriptionsNotSupported, "No broker found for global subscription." if broker.nil?
      broker.add_thread_global_subscription(subscriber)
    end

    def all_subscriptions_for(topic)
      @brokers.flat_map { |broker| broker.all_subscriptions_for(topic) }
    end

    def verify(topic)
      !!verified_broker(topic)
    end

    private

    def verified_broker(topic)
      @brokers.find { |broker| broker.verify(topic) }
    end
  end
end
