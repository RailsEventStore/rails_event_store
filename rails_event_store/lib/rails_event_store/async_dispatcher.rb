module RailsEventStore
  module AsyncProxyStrategy
    class AfterCommit
      def call(klass, serialized_event, async_call)
        if ActiveRecord::Base.connection.transaction_open?
          ActiveRecord::Base.
            connection.
            current_transaction.
            add_record(AsyncRecord.new(klass, serialized_event, async_call))
        else
          async_call.call(klass, serialized_event)
        end
      end

      private
      class AsyncRecord
        def initialize(klass, serialized_event, async_call)
          @klass = klass
          @serialized_event = serialized_event
          @async_call = async_call
        end

        def committed!
          async_call.call(klass, serialized_event)
        end

        def rolledback!(*)
        end

        def before_committed!
        end

        def add_to_transaction
          AfterCommit.new.call(klass, serialized_event, async_call)
        end

        attr_reader :serialized_event, :klass, :async_call
      end
    end

    class Inline
      def call(klass, serialized_event, async_call)
        async_call.call(klass, serialized_event)
      end
    end
  end

  class AsyncDispatcher < RubyEventStore::PubSub::Dispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new, async_call:)
      @async_proxy_strategy = proxy_strategy
      @async_call = async_call
    end

    def call(subscriber, _, serialized_event)
      if @async_call.async_handler?(subscriber)
        @async_proxy_strategy.call(subscriber, serialized_event, @async_call)
      else
        super
      end
    end

    def verify(subscriber)
      super unless @async_call.async_handler?(subscriber)
    end
  end
end
