require 'active_job'

module RailsEventStore
  class ActiveJobDispatcher
    def call(subscriber, event)
      subscriber.call(event)
    end

    def proxy_for(klass)
      async_handler?(klass) ? async_proxy(klass) : sync_proxy(klass)
    end

    private
    def async_handler?(klass)
      klass < ActiveJob::Base
    end

    def sync_proxy(klass)
      raise InvalidHandler.new(klass) unless klass.method_defined?(:call)
      ->(e) { klass.new.call(e) }
    end

    def async_proxy(klass)
      ->(e) {
        if ActiveRecord::Base.connection.transaction_open?
          ActiveRecord::Base.
            connection.
            current_transaction.
            add_record(AsyncRecord.new(klass, e))
        else
          klass.perform_later(YAML.dump(e))
        end
      }
    end

    class AsyncRecord
      def initialize(klass, event)
        @klass = klass
        @event = event
      end

      def committed!
        @klass.perform_later(YAML.dump(@event))
      end
    end
  end
end
