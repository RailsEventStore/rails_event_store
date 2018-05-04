require 'active_job'

module RailsEventStore
  module AsyncProxyStrategy
    class AfterCommit
      def call(klass, serialized_event)
        if ActiveRecord::Base.connection.transaction_open?
          ActiveRecord::Base.
            connection.
            current_transaction.
            add_record(AsyncRecord.new(klass, serialized_event))
        else
          klass.perform_later(serialized_event)
        end
      end

      private
      class AsyncRecord
        def initialize(klass, serialized_event)
          @klass = klass
          @serialized_event = serialized_event
        end

        def committed!
          klass.perform_later(serialized_event)
        end

        def rolledback!(*)
        end

        def before_committed!
        end

        def add_to_transaction
          AfterCommit.new.call(klass, serialized_event)
        end

        attr_reader :serialized_event, :klass
      end
    end

    class Inline
      def call(klass, serialized_event)
        klass.perform_later(serialized_event)
      end
    end
  end

  class ActiveJobDispatcher < RubyEventStore::PubSub::Dispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new)
      @async_proxy_strategy = proxy_strategy
    end

    def call(subscriber, event, serialized_event)
      if async_handler?(subscriber)
        @async_proxy_strategy.call(subscriber, serialized_event)
      else
        super
      end
    end

    def verify(subscriber)
      super unless async_handler?(subscriber)
    end

    private

    def async_handler?(klass)
      Class === klass && klass < ActiveJob::Base
    end

  end
end