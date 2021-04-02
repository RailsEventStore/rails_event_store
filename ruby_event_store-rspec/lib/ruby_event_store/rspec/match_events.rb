module RubyEventStore
  module RSpec
    class MatchEvents
      def call(expected, events)
        if match_events?(expected)
          matcher(expected).matches?(events) && matches_count?(expected, events)
        else
          !events.empty?
        end
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

      def match_events?(expected)
        !expected.events.empty?
      end
    end
  end
end
