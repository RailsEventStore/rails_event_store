module RailsEventStore
  class AfterCommitAsyncDispatcher
    def initialize(scheduler:)
      @scheduler = scheduler
    end

    def call(subscriber, _, serialized_event)
      run do
        @scheduler.call(subscriber, serialized_event)
      end
    end

    def run(&schedule_proc)
      if ActiveRecord::Base.connection.transaction_open?
        ActiveRecord::Base.
          connection.
          current_transaction.
          add_record(AsyncRecord.new(self, schedule_proc))
      else
        yield
      end
    end

    def verify(subscriber)
      @scheduler.verify(subscriber)
    end

    private
    class AsyncRecord
      def initialize(dispatcher, schedule_proc)
        @dispatcher = dispatcher
        @schedule_proc = schedule_proc
      end

      def committed!(*)
        schedule_proc.call
      end

      def rolledback!(*)
      end

      def before_committed!
      end

      def add_to_transaction
        dispatcher.run(&schedule_proc)
      end

      attr_reader :schedule_proc, :dispatcher
    end
  end
end
