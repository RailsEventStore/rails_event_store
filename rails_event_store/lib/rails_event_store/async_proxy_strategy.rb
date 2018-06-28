module RailsEventStore
  module AsyncProxyStrategy
    class AfterCommit
      def call(schedule_proc)
        if ActiveRecord::Base.connection.transaction_open?
          ActiveRecord::Base.
            connection.
            current_transaction.
            add_record(AsyncRecord.new(schedule_proc))
        else
          schedule_proc.call
        end
      end

      private
      class AsyncRecord
        def initialize(schedule_proc)
          @schedule_proc = schedule_proc
        end

        def committed!
          schedule_proc.call
        end

        def rolledback!(*)
        end

        def before_committed!
        end

        def add_to_transaction
          AfterCommit.new.call(schedule_proc)
        end

        attr_reader :schedule_proc
      end
    end
  end
end
