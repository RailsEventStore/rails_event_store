module RubyEventStore
  module PubSub
    class Dispatcher
      def call(subscriber, event)
        subscriber = subscriber.new if Class === subscriber
        subscriber.call(event)
      end

      def verify(subscriber)
        subscriber = subscriber.new if Class === subscriber
        subscriber.respond_to?(:call) or raise InvalidHandler.new(subscriber)
      rescue ArgumentError
        raise InvalidHandler.new(subscriber)
      end
    end
  end
end
