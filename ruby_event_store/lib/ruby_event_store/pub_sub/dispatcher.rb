module RubyEventStore
  module PubSub
    class Dispatcher
      def call(subscriber, event)
        ensure_method_defined(subscriber)
        subscriber.call(event)
      end

      private
      def ensure_method_defined(subscriber)
        raise MethodNotDefined.new(subscriber) unless subscriber.respond_to?(:call)
      end
    end
  end
end
