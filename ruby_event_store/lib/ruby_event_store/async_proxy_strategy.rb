module RubyEventStore
  module AsyncProxyStrategy
    class Inline
      def call(schedule_proc)
        schedule_proc.call
      end
    end
  end
end
