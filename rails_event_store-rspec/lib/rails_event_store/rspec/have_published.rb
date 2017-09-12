module RailsEventStore
  module RSpec
    class HavePublished
      def initialize(expected)
        @matcher = ::RSpec::Matchers::BuiltIn::Include.new(expected)
      end

      def matches?(actual)
        @matcher.matches?(actual.read_all_streams_backward)
      end
    end
  end
end
