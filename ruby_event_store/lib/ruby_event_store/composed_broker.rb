# frozen_string_literal: true

module RubyEventStore
  class ComposedBroker
    def initialize(*brokers, multiple_brokers: false)
      @brokers = brokers
      @multiple_brokers = multiple_brokers
    end

    def call(event, record, topic)
      brokers = verified_brokers(topic)
      if brokers.empty?
        warn "No broker found for topic '#{topic}'. Event #{event.event_id} will not be processed."
      else
        brokers.each { |broker| broker.call(event, record, topic) }
      end
    end

    def add_subscription(subscriber, topics)
      topics.each do |topic|
        brokers = verified_brokers(topic)
        raise SubscriptionsNotSupported, "No broker found for topic '#{topic}'." if brokers.empty?
        brokers.each { |broker| broker.add_subscription(subscriber, topic) }
      end
    end

    def add_global_subscription(subscriber)
      brokers = verified_brokers(nil)
      raise SubscriptionsNotSupported, "No broker found for global subscription." if brokers.empty?
      brokers.each { |broker| broker.add_global_subscription(subscriber) }
    end

    def add_thread_subscription(subscriber, topics)
      topics.each do |topic|
        brokers = verified_brokers(topic)
        raise SubscriptionsNotSupported, "No broker found for topic '#{topic}'." if brokers.empty?
        brokers.each { |broker| broker.add_thread_subscription(subscriber, topic) }
      end
    end

    def add_thread_global_subscription(subscriber)
      brokers = verified_brokers(nil)
      raise SubscriptionsNotSupported, "No broker found for global subscription." if brokers.empty?
      brokers.each { |broker| broker.add_thread_global_subscription(subscriber) }
    end

    def all_subscriptions_for(topic)
      @brokers.flat_map { |broker| broker.all_subscriptions_for(topic) }
    end

    def verify(topic)
      !verified_brokers(topic).empty?
    end

    private

    def verified_brokers(topic)
      if @multiple_brokers
        @brokers.select { |broker| broker.verify(topic) }
      else
        [@brokers.find { |broker| broker.verify(topic) }].compact
      end
    end
  end
end
