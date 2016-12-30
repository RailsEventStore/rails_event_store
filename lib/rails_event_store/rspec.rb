module RailsEventStore
  module RSpecMatchers
    class BeEvent
      def initialize(expected)
        @expected = expected
      end

      def matches?(target)
        @target = target
        @expected === @target
      end

      def failure_message
        %Q{
expected: #{@expected}
     got: #{@target.class}
        }
      end

      def failure_message_when_negated
        %Q{
expected: not kind of #{@expected}
     got: #{@target.class}
        }
      end

      def description
        "be an event of kind #{@expected}"
      end
    end

    def be_event(expected)
      BeEvent.new(expected)
    end
    alias :an_event :be_event
  end
end

