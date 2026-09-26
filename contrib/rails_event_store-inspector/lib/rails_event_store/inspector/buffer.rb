# frozen_string_literal: true

module RailsEventStore
  module Inspector
    class Buffer
      DEFAULT_LIMIT = 500

      def initialize(limit: DEFAULT_LIMIT)
        @limit = limit
        @mutex = Mutex.new
        @entries = []
      end

      def push(entry)
        @mutex.synchronize do
          @entries.push(entry)
          @entries.shift while @entries.size > @limit
        end
      end

      def to_a
        @mutex.synchronize { @entries.dup }
      end

      def clear(&predicate)
        @mutex.synchronize do
          predicate ? @entries.reject!(&predicate) : @entries.clear
        end
        nil
      end
    end
  end
end
