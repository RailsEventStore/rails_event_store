module RailsEventStore
  module RSpec
    class HavePublished
      def initialize(expected)
        @matcher = ::RSpec::Matchers::BuiltIn::Include.new(expected)
      end

      def matches?(event_store)
        @matcher.matches?(event_store.read_all_streams_backward)
      end
    end
  end
end
