require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe HaveApplied do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:aggregate_root) { TestAggregate.new }

      def matcher(*expected)
        HaveApplied.new(*expected, differ: colorless_differ, formatter: formatter)
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      def formatter
        ::RSpec::Support::ObjectFormatter.method(:format)
      end

      specify do
        expect(aggregate_root).not_to matcher(matchers.an_event(FooEvent))
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent))
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).not_to matcher(matchers.an_event(BazEvent))
      end

      specify do
        aggregate_root.foo
        aggregate_root.foo
        expect(aggregate_root).not_to matcher(matchers.an_event(FooEvent)).exactly(1)
      end

      specify do
        aggregate_root.foo
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).exactly(2)
      end

      specify do
        aggregate_root.foo
        aggregate_root.bar
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).exactly(1)
      end

      specify do
        aggregate_root.foo
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).exactly(2).times
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).exactly(1).time
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).once
      end

      specify do
        aggregate_root.foo
        aggregate_root.foo
        expect(aggregate_root).not_to matcher(matchers.an_event(FooEvent)).once
      end

      specify do
        aggregate_root.foo
        aggregate_root.bar

        expect(aggregate_root).to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BarEvent)
        )
      end

      specify do
        aggregate_root.foo

        expect(aggregate_root).not_to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        aggregate_root.foo
        aggregate_root.bar

        expect(aggregate_root).not_to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        aggregate_root.foo
        aggregate_root.bar

        expect{
          expect(aggregate_root).to matcher(
            matchers.an_event(FooEvent),
            matchers.an_event(BarEvent)
          ).exactly(2).times
        }.to raise_error(NotSupported)
      end

      specify { expect{ HaveApplied.new() }.to raise_error(ArgumentError) }

      specify do
        aggregate_root.foo
        _matcher = matcher(matchers.an_event(BarEvent))
        _matcher.matches?(aggregate_root)

        expect(_matcher.failure_message.to_s).to include("] to be applied")
        expect(_matcher.failure_message.to_s).to include("-[#<FooEvent")
        expect(_matcher.failure_message.to_s).to include("BeEvent")

        expect(_matcher.failure_message_when_negated.to_s).to include("] not to be applied")
        expect(_matcher.failure_message_when_negated.to_s).to include("-[#<FooEvent")
        expect(_matcher.failure_message_when_negated.to_s).to include("BeEvent")
      end

      specify do
        _matcher = matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
        expect(_matcher.description)
          .to eq("have applied [be event FooEvent, be event BazEvent]")
      end

      specify do
        _matcher = matcher(
          FooEvent,
          BazEvent
        )
        expect(_matcher.description)
          .to eq("have applied [FooEvent, BazEvent]")
      end
    end
  end
end
