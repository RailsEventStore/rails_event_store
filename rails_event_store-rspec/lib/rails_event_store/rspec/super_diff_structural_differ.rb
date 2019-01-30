require 'super_diff'

module RailsEventStore
  module RSpec
    class SuperDiffStructuralDiffer
      def initialize(color: true)
        @color = color
      end

      def diff(expected, actual)
        result = SuperDiff::EqualityMatcher.call(expected: expected, actual: actual)
        return result if result.blank?

        result = "#{result}\n"
        color ? result : without_colors(result)
      end

      private

      attr_reader :color

      def without_colors(output)
        output.gsub(/\e\[([;\d]+)?m/, '')
      end
    end
  end
end
