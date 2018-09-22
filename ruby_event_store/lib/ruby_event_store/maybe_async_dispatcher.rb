module RubyEventStore
  class MaybeAsyncDispatcher
    def initialize(async_dispatcher:, async_handler_strategy:)
      @async_dispatcher = async_dispatcher
      @sync_dispatcher = PubSub::Dispatcher.new
      @async_handler_strategy = async_handler_strategy
    end

    def call(subscriber, event, serialized_event)
      if async_handler?(subscriber)
        @async_dispatcher.call(subscriber, event, serialized_event)
      else
        @sync_dispatcher.call(subscriber, event, serialized_event)
      end
    end

    def verify(subscriber)
      if async_handler?(subscriber)
        @async_dispatcher.verify(subscriber)
      else
        @sync_dispatcher.verify(subscriber)
      end
    end

    private

    def async_handler?(subscriber)
      @async_handler_strategy.call(subscriber)
    end
  end
end
