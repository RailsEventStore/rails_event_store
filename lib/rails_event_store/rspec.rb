module RailsEventStore
  module RSpecMatchers
    class BeEvent
      def initialize(expected)
        @expected = expected
      end

      def matches?(target)
        @target = target
        matches_kind? &&
        matches_data? &&
        matches_metadata?
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

      def with_data(data)
        @target_data = data
        self
      end
      alias :and_data :with_data

      def with_metadata(metadata)
        @target_metadata = metadata
        self
      end
      alias :and_metadata :with_metadata

      private

      def matches_kind?
        @expected === @target
      end

      def matches_data?
        return true unless @target_data
        @target_data.all? { |k, v| @target.data[k] == v }
      end

      def matches_metadata?
        return true unless @target_metadata
        @target_metadata.all? { |k, v| @target.metadata[k] == v }
      end
    end

    def be_event(expected)
      BeEvent.new(expected)
    end
    alias :an_event :be_event
  end
end

