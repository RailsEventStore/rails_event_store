module RubyEventStore
  module RSpec
    class ExpectedCollection
      def initialize(events)
        @events = events
      end

      attr_reader :events
    end
  end
end
