module RubyEventStore
  module PubSub
    class Dispatcher
      def call(subscriber, event)
        raise InvalidHandler.new(subscriber) unless subscriber.respond_to?(:call)
        subscriber.call(event)
      end
    end
  end
end
