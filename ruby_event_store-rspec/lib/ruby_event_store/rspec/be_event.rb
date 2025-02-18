# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class BeEvent
      class KindMatcher
        def initialize(expected)
          @expected = expected
        end

        def matches?(actual)
          @expected === actual
        end
      end

      class DataMatcher
        def initialize(expected, strict:)
          @strict = strict
          @expected = expected
        end

        def matches?(actual)
          return true unless @expected
          matcher = @strict ? ::RSpec::Matchers::BuiltIn::Match : ::RSpec::Matchers::BuiltIn::Include
          matcher.new(@expected).matches?(actual)
        end
      end

      class FailureMessage
        class ExpectedLine
          def initialize(expected_klass, expected_metadata, expected_data, formatter:)
            @expected_klass = expected_klass
            @expected_metadata = expected_metadata
            @expected_data = expected_data
            @formatter = formatter
          end

          def to_s
            ["\nexpected: ", @expected_klass, with, metadata, data]
          end

          private

          def with
            " with" if [@expected_data, @expected_metadata].any?
          end

          def data
            [" data: ", @formatter.(@expected_data)] if @expected_data
          end

          def metadata
            [" metadata: ", @formatter.(@expected_metadata)] if @expected_metadata
          end
        end

        class ActualLine
          def initialize(actual_klass, actual_metadata, actual_data, expected_metadata, expected_data, formatter:)
            @actual_klass = actual_klass
            @actual_metadata = actual_metadata
            @actual_data = actual_data
            @expected_metadata = expected_metadata
            @expected_data = expected_data
            @formatter = formatter
          end

          def to_s
            ["\n     got: ", @actual_klass, with, metadata, data, "\n"]
          end

          private

          def with
            " with" if [@expected_data, @expected_metadata].any?
          end

          def data
            [" data: ", @formatter.(@actual_data)] if @expected_data
          end

          def metadata
            [" metadata: ", @formatter.(@actual_metadata)] if @expected_metadata
          end
        end

        class Diff
          def initialize(actual, expected, label, differ:, formatter:)
            @actual = actual
            @expected = expected
            @label = label
            @differ = differ
            @formatter = formatter
          end

          def to_s
            @expected && ["\n#{@label} diff:", @differ.diff(@formatter.(@actual) + "\n", @formatter.(@expected))]
          end
        end

        def initialize(
          expected_klass,
          actual_klass,
          expected_data,
          actual_data,
          expected_metadata,
          actual_metadata,
          differ:,
          formatter:
        )
          @expected_klass = expected_klass
          @actual_klass = actual_klass
          @expected_data = expected_data
          @actual_data = actual_data
          @expected_metadata = expected_metadata
          @actual_metadata = actual_metadata
          @differ = differ
          @formatter = formatter
        end

        def to_s
          [
            ExpectedLine.new(@expected_klass, @expected_metadata, @expected_data, formatter: @formatter),
            ActualLine.new(@actual_klass, @actual_metadata.to_h, @actual_data, @expected_metadata, @expected_data, formatter: @formatter),
            Diff.new(@actual_metadata.to_h, @expected_metadata, "Metadata", differ: @differ, formatter: @formatter),
            Diff.new(@actual_data, @expected_data, "Data", differ: @differ, formatter: @formatter)
          ].map(&:to_s).join
        end
      end

      include ::RSpec::Matchers::Composable

      def initialize(expected, differ:, formatter:)
        @expected = expected
        @differ = differ
        @formatter = formatter
      end

      def matches?(actual)
        @actual = actual
        matches_kind?(actual) && matches_data?(actual) && matches_metadata?(actual)
      end

      def with_data(expected_data)
        @expected_data = expected_data
        self
      end

      def with_metadata(expected_metadata)
        @expected_metadata = expected_metadata
        self
      end

      def failure_message
        actual_data = actual.data if actual.respond_to?(:data)
        actual_metadata = actual.metadata if actual.respond_to?(:metadata)
        FailureMessage.new(
          expected,
          actual.class,
          expected_data,
          actual_data,
          expected_metadata,
          actual_metadata,
          differ: differ,
          formatter: formatter
        ).to_s
      end

      def failure_message_when_negated
        "
expected: not a kind of #{expected}
     got: #{actual.class}
"
      end

      def strict
        @strict = true
        self
      end

      def description
        "be an event #{formatter.(expected)}#{data_and_metadata_expectations_description}"
      end

      def data_and_metadata_expectations_description
        predicate = strict? ? "matching" : "including"
        expectation_list = []
        expectation_list << "with data #{predicate} #{formatter.(expected_data)}" if expected_data
        expectation_list << "with metadata #{predicate} #{formatter.(expected_metadata)}" if expected_metadata
        " (#{expectation_list.join(" and ")})" if expectation_list.any?
      end

      attr_reader :expected, :expected_data, :expected_metadata

      def strict?
        @strict
      end

      def matches_kind?(actual_event)
        KindMatcher.new(expected).matches?(actual_event)
      end

      private

      def matches_data?(actual_event)
        DataMatcher.new(expected_data, strict: strict?).matches?(actual_event.data)
      end

      def matches_metadata?(actual_event)
        DataMatcher.new(expected_metadata, strict: strict?).matches?(actual_event.metadata.to_h)
      end

      attr_reader :actual, :differ, :formatter
    end
  end
end
