require 'super_diff'

module RailsEventStore
  module RSpec
    class SuperDiffStructuralDiffer
      def initialize(color: true)
        @color = color
      end

      def diff(expected, actual)
        result = SuperDiff::EqualityMatcher.call(expected: expected, actual: actual)
        color ? result : color_blind(result)
      end

      private

      attr_reader :color

      def color_blind(output)
        output.gsub(/\e\[([;\d]+)?m/, '')
      end
    end
  end
end
