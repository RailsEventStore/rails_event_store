module RailsEventStore
  module RSpec
    class HaveApplied
      def initialize(expected)
        @matcher = ::RSpec::Matchers::BuiltIn::Include.new(expected)
      end

      def matches?(aggregate_root)
        @matcher.matches?(aggregate_root.__send__(:unpublished_events))
      end
    end
  end
end

