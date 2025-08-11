# frozen_string_literal: true

module RubyEventStore
  class Broker
    def initialize(subscriptions: Subscriptions.new, dispatcher: Dispatcher.new)
      @subscriptions = subscriptions
      @dispatcher = dispatcher
    end

    def call(topic, event, record)
      subscribers = subscriptions.all_for(topic)
      subscribers.each { |subscriber| dispatcher.call(subscriber, event, record) }
    end

    def add_subscription(subscriber, topics)
      verify_subscription(subscriber)
      subscriptions.add_subscription(subscriber, topics)
    end

    def add_global_subscription(subscriber)
      verify_subscription(subscriber)
      subscriptions.add_global_subscription(subscriber)
    end

    def add_thread_subscription(subscriber, topics)
      verify_subscription(subscriber)
      subscriptions.add_thread_subscription(subscriber, topics)
    end

    def add_thread_global_subscription(subscriber)
      verify_subscription(subscriber)
      subscriptions.add_thread_global_subscription(subscriber)
    end

    def all_subscriptions_for(topic)
      subscriptions.all_for(topic)
    end

    def cleaner_inspect(indent: 0)
      <<~EOS.chomp
        #{' ' * indent}#<#{self.class}:0x#{__id__.to_s(16)}>
        #{' ' * indent}  - dispatcher: #{dispatcher.inspect}
      EOS
    end

    private

    attr_reader :dispatcher, :subscriptions

    def verify_subscription(subscriber)
      raise SubscriberNotExist, "subscriber must be first argument or block" unless subscriber
      unless dispatcher.verify(subscriber)
        raise InvalidHandler.new("Handler #{subscriber} is invalid for dispatcher #{dispatcher}")
      end
    end
  end
end
