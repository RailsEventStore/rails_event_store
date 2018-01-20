require 'active_job'

module RailsEventStore
  module AsyncProxyStrategy
    class AfterCommit
      def call(klass, event)
        if ActiveRecord::Base.connection.transaction_open?
          ActiveRecord::Base.
            connection.
            current_transaction.
            add_record(AsyncRecord.new(klass, event))
        else
          klass.perform_later(YAML.dump(event))
        end
      end

      private
      class AsyncRecord
        def initialize(klass, event)
          @klass = klass
          @event = event
        end

        def committed!
          @klass.perform_later(YAML.dump(@event))
        end

        def rolledback!(*)
        end

        def before_committed!
        end

        def add_to_transaction
          AfterCommit.new.call(@klass, @event)
        end
      end
    end

    class Inline
      def call(klass, event)
        klass.perform_later(YAML.dump(event))
      end
    end
  end

  class ActiveJobDispatcher < RubyEventStore::PubSub::Dispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new)
      @async_proxy_strategy = proxy_strategy
    end

    def call(subscriber, event)
      if async_handler?(subscriber)
        @async_proxy_strategy.call(subscriber, event)
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