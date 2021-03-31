module RubyEventStore
  module RSpec
    class MatchEvents
      def call(expected, events)
        matcher(expected).matches?(events) && matches_count?(expected, events)
      end

      private

      def matches_count?(expected, events)
        return true unless expected.specified_count?
        events.select { |e| expected.event === e }.size.equal?(expected.count)
      end

      def matcher(expected)
        if expected.strict?
          ::RSpec::Matchers::BuiltIn::Match.new(expected.events)
        else
          ::RSpec::Matchers::BuiltIn::Include.new(*expected.events)
        end
      end
    end
  end
end
