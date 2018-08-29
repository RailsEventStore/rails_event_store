module RailsEventStore
  class AfterCommitAsyncDispatcher
    def initialize(scheduler:)
      @scheduler = scheduler
    end

    def call(subscriber, _, serialized_event)
      if ActiveRecord::Base.connection.transaction_open?
        ActiveRecord::Base.
          connection.
          current_transaction.
          add_record(AsyncRecord.new(->() { @scheduler.call(subscriber, serialized_event) }))
      else
        @scheduler.call(subscriber, serialized_event)
      end
    end

    def verify(subscriber)
      @scheduler.verify(subscriber)
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
