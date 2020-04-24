require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe Apply do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:aggregate) { TestAggregate.new }

      def matcher(*expected)
        Apply.new(*expected)
      end

      specify do
        expect {
          expect {
            true
          }.to matcher
        }.to raise_error(SyntaxError, "You have to set the aggregate instance with `in`, e.g. `expect { ... }.to apply(an_event(MyEvent)).in(aggregate)`")
      end

      specify do
        expect {
          true
        }.not_to matcher.in(aggregate)
      end

      specify do
        expect {
          aggregate.foo
        }.to matcher.in(aggregate)
      end

      specify do
        expect {
          aggregate.foo
        }.not_to matcher(matchers.an_event(BarEvent)).in(aggregate)
      end

      specify do
        expect {
          aggregate.foo
        }.to matcher(matchers.an_event(FooEvent)).in(aggregate)
      end

      specify do
        aggregate.foo
        aggregate.foo
        aggregate.foo
        expect {
          aggregate.bar
        }.to matcher(matchers.an_event(BarEvent)).in(aggregate)
        expect {
          aggregate.bar
        }.not_to matcher(matchers.an_event(FooEvent)).in(aggregate)
      end

      specify do
        expect {
          aggregate.foo
          aggregate.bar
        }.to matcher(matchers.an_event(FooEvent), matchers.an_event(BarEvent)).in(aggregate)
      end

      specify do
        aggregate.foo
        expect {
          aggregate.bar
        }.not_to matcher(matchers.an_event(FooEvent)).in(aggregate)
      end

      specify do
        matcher_ = matcher.in(aggregate)
        matcher_.matches?(Proc.new { })

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS.strip)
          expected block not to have applied any events
        EOS
      end

      specify do
        matcher_ = matcher.in(aggregate)
        matcher_.matches?(Proc.new { })

        expect(matcher_.failure_message.to_s).to eq(<<~EOS.strip)
          expected block to have applied any events
        EOS
      end

      specify do
        matcher_ = matcher(actual = matchers.an_event(FooEvent)).in(aggregate)
        matcher_.matches?(Proc.new { })

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
          expected block to have applied:

          #{[actual].inspect}

          but applied:

          []
        EOS
      end

      specify do
        foo_event = matchers.an_event(FooEvent).with_data(any: :thing)
        matcher_ = matcher(foo_event).in(aggregate)
        matcher_.matches?(Proc.new { aggregate.foo })
        actual = aggregate.unpublished_events.first

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
          expected block to have applied:

          #{[foo_event].inspect}

          but applied:

          #{[actual].inspect}
        EOS
      end

      specify do
        foo_event = matchers.an_event(FooEvent)
        matcher_ = matcher(foo_event).in(aggregate)
        matcher_.matches?(Proc.new { aggregate.foo })
        actual = aggregate.unpublished_events.first

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS)
          expected block not to have applied:

          #{[foo_event].inspect}

          but applied:

          #{[actual].inspect}
        EOS
      end

      specify do
        expect {
          aggregate.foo
          aggregate.bar
        }.to matcher(matchers.an_event(FooEvent), matchers.an_event(BarEvent)).in(aggregate).strict
      end

      specify do
        expect {
          aggregate.foo
          aggregate.bar
        }.not_to matcher(matchers.an_event(BarEvent)).in(aggregate).strict
      end

      specify do
        matcher_ = matcher
        expect(matcher_.description).to eq("apply events")
      end
    end
  end
end
