module RubyEventStore
  module AsyncProxyStrategy
    # @deprecated Use RubyEventStore::ImmediateAsyncDispatcher instead
    class Inline
      def initialize
        warn <<~EOW
          RubyEventStore::AsyncProxyStrategy::Inline has been deprecated.

          Use RubyEventStore::ImmediateAsyncDispatcher instead
        EOW
      end

      def call(schedule_proc)
        schedule_proc.call
      end
    end
  end
end
