module RailsEventStore
  module AsyncProxyStrategy
    class AfterCommit
      def call(async_call)
        if ActiveRecord::Base.connection.transaction_open?
          ActiveRecord::Base.
            connection.
            current_transaction.
            add_record(AsyncRecord.new(async_call))
        else
          async_call.call
        end
      end

      private
      class AsyncRecord
        def initialize(async_call)
          @async_call = async_call
        end

        def committed!
          async_call.call
        end

        def rolledback!(*)
        end

        def before_committed!
        end

        def add_to_transaction
          AfterCommit.new.call(async_call)
        end

        attr_reader :async_call
      end
    end

    class Inline
      def call(async_call)
        async_call.call
      end
    end
  end
end
