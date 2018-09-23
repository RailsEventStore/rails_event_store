module RubyEventStore
  # @deprecated Use RubyEventStore::ImmediateAsyncDispatcher instead
  class AsyncDispatcher < PubSub::Dispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new, scheduler:)
      @async_proxy_strategy = proxy_strategy
      @scheduler = scheduler
      warn <<~EOW
        RubyEventStore::AsyncDispatcher has been deprecated.

        Use RubyEventStore::ImmediateAsyncDispatcher instead
      EOW
    end

    def call(subscriber, _, serialized_event)
      if @scheduler.async_handler?(subscriber)
        @async_proxy_strategy.call(->{ @scheduler.call(subscriber, serialized_event) })
      else
        super
      end
    end

    def verify(subscriber)
      @scheduler.async_handler?(subscriber) || super
    end
  end
end
