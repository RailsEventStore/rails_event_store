module RubyEventStore
  module RSpec
    class FetchEvents
      def from(event_id)
        @start = event_id
      end

      attr_reader :start
    end
  end
end
