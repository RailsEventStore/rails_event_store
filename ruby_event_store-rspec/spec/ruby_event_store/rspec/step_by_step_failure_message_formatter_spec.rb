# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module RSpec
    ::RSpec.describe StepByStepFailureMessageFormatter::HavePublished do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:aggregate) { TestAggregate.new }
      let(:event_store) do
        Client.new(
          mapper: Mappers::PipelineMapper.new(Mappers::Pipeline.new(to_domain_event: Transformations::IdentityMap.new)),
        )
      end

      def matcher(*expected)
        HavePublished.new(
          *expected,
          phraser: phraser,
          failure_message_formatter: failure_message_formatter.have_published(colorless_differ),
        )
      end

      def have_applied_matcher(*expected)
        HaveApplied.new(
          *expected,
          phraser: phraser,
          failure_message_formatter: failure_message_formatter.have_applied(colorless_differ),
        )
      end

      def publish_matcher(*expected)
        Publish.new(*expected, failure_message_formatter: failure_message_formatter.publish(colorless_differ))
      end

      def apply_matcher(*expected)
        Apply.new(*expected, failure_message_formatter: failure_message_formatter.apply(colorless_differ))
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      def phraser
        Matchers::ListPhraser
      end

      def failure_message_formatter
        StepByStepFailureMessageFormatter.new
      end

      specify do
        event_store.publish(FooEvent.new(data: { a: 1 }))
        event_store.publish(actual = FooEvent.new(data: { a: 2 }))
        event_store.publish(FooEvent.new(data: { a: 1 }))
        matcher_ = matcher(matchers.an_event(FooEvent).with_data(a: 1)).exactly(3).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event
          be an event FooEvent (with data including #{formatter[a: 1]})
        to be published 3 times
        but was published 2 times

        There are events of correct type but with incorrect payload:
        1) #{actual.inspect}
            data diff:
            @@ -1,2 +1,2 @@
            -:a => 2,
            +:a => 1,
        EOS
      end

      specify do
        event_store.publish(actual1 = FooEvent.new)
        event_store.publish(actual2 = FooEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent)).exactly(3).times.strict
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected only
          be an event FooEvent
        to be published 3 times

        but the following was published: [
          #{actual1.inspect}
          #{actual2.inspect}
        ]
        EOS
      end

      specify do
        event_store.publish(FooEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent)).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event
          be an event FooEvent
        to be published 2 times
        but was published 1 times
        EOS
      end

      specify do
        event_store.publish(actual1 = FooEvent.new(data: { foo: 123 }))
        event_store.publish(actual2 = FooEvent.new(data: { foo: 234 }))
        matcher_ = matcher(matchers.an_event(FooEvent).with_data({ foo: 124 })).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event
          be an event FooEvent (with data including #{formatter[foo: 124]})
        to be published 2 times, but it was not published

        There are events of correct type but with incorrect payload:
        1) #{actual1.inspect}
            data diff:
            @@ -1,2 +1,2 @@
            -:foo => 123,
            +:foo => 124,
        2) #{actual2.inspect}
            data diff:
            @@ -1,2 +1,2 @@
            -:foo => 234,
            +:foo => 124,
        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new(data: { foo: 123 }))
        matcher_ = matcher(matchers.an_event(FooEvent).with_data({ foo: 124 }))
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including #{formatter[foo: 124]})
        ] to be published

        i.e. expected event
          be an event FooEvent (with data including #{formatter[foo: 124]})
        to be published, but it was not published

        There are events of correct type but with incorrect payload:
        1) #{actual.inspect}
            data diff:
            @@ -1,2 +1,2 @@
            -:foo => 123,
            +:foo => 124,
        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new(metadata: { foo: 123 }))
        matcher_ = matcher(matchers.an_event(FooEvent).with_metadata({ foo: 124 }))
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with metadata including #{formatter[foo: 124]})
        ] to be published

        i.e. expected event
          be an event FooEvent (with metadata including #{formatter[foo: 124]})
        to be published, but it was not published

        There are events of correct type but with incorrect payload:
        1) #{actual.inspect}
            metadata diff:
            @@ -1,5 +1,2 @@
            -:correlation_id => #{actual.correlation_id.inspect},
            -:foo => 123,
            -:timestamp => #{formatter.call(actual.timestamp)},
            -:valid_at => #{formatter.call(actual.valid_at)},
            +:foo => 124,
        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new(data: { foo: 123, bar: 20 }))
        matcher_ = matcher(matchers.an_event(FooEvent).with_data({ foo: 123 }).strict)
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data matching #{formatter[foo: 123]})
        ] to be published

        i.e. expected event
          be an event FooEvent (with data matching #{formatter[foo: 123]})
        to be published, but it was not published

        There are events of correct type but with incorrect payload:
        1) #{actual.inspect}
            data diff:
            @@ -1,3 +1,2 @@
            -:bar => 20,
             :foo => 123,
        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new(data: { a: 1, b: 2 }))
        expected = [matchers.an_event(FooEvent).with_data({ a: 1 }), matchers.an_event(FooEvent).with_data({ b: 3 })]
        matcher_ = matcher(*expected)
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including #{formatter[a: 1]})
          be an event FooEvent (with data including #{formatter[b: 3]})
        ] to be published

        i.e. expected event
          be an event FooEvent (with data including #{formatter[b: 3]})
        to be published, but it was not published

        There are events of correct type but with incorrect payload:
        1) #{actual.inspect}
            data diff:
            @@ -1,3 +1,2 @@
            -:a => 1,
            -:b => 2,
            +:b => 3,
        EOS
      end

      specify do
        event_store.publish(BazEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent))
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent
        ] to be published

        i.e. expected event
          be an event FooEvent
        to be published, but there is no event with such type
        EOS
      end

      specify do
        event_store.publish(BazEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent)).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event
          be an event FooEvent
        to be published 2 times, but there is no event with such type
        EOS
      end

      specify do
        event_store.publish(actual = BazEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent)).strict
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected only [
          be an event FooEvent
        ] to be published

        but the following was published: [
          #{actual.inspect}
        ]
        EOS
      end

      specify do
        event_store.publish(actual1 = FooEvent.new)
        event_store.publish(actual2 = FooEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent))
        matcher_.matches?(event_store)

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent
        ] not to be published

        but the following was published: [
          #{actual1.inspect}
          #{actual2.inspect}
        ]
        EOS
      end

      specify do
        event_store.publish(actual1 = FooEvent.new)
        event_store.publish(actual2 = FooEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent)).strict
        matcher_.matches?(event_store)

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent
        ] not to exactly be published

        but the following was published: [
          #{actual1.inspect}
          #{actual2.inspect}
        ]
          EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent)).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS)
        expected
          be an event FooEvent
        not to be published exactly 2 times

        but the following was published: [
          #{actual.inspect}
        ]
          EOS
      end

      specify do
        event_store.publish(FooEvent.new(data: { a: 1 }))
        event_store.publish(FooEvent.new(data: { a: 1 }))
        event_store.publish(FooEvent.new(data: { a: 2 }))
        expected = [matchers.an_event(FooEvent).with_data(a: 1), matchers.an_event(BarEvent)]
        matcher_ = matcher(*expected)
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including #{formatter[a: 1]})
          be an event BarEvent
        ] to be published

        i.e. expected event
          be an event BarEvent
        to be published, but there is no event with such type
        EOS
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Foo")
        matcher_ = matcher(matchers.an_event(FooEvent)).in_streams(%w[Foo Bar])
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent
        ] to be published in stream Bar

        i.e. expected event
          be an event FooEvent
        to be published, but there is no event with such type
        EOS
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Bar")
        matcher_ = matcher(matchers.an_event(FooEvent)).in_streams(%w[Foo Bar])
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent
        ] to be published in stream Foo

        i.e. expected event
          be an event FooEvent
        to be published, but there is no event with such type
        EOS
      end

      specify do
        event_store.publish(FooEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent)).in_stream("Foo").once
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event
          be an event FooEvent
        to be published 1 times in stream Foo, but there is no event with such type
        EOS
      end

      specify do
        actual = nil
        matcher_ = publish_matcher(matchers.an_event(FooEvent).with_data(a: 2)).in(event_store)
        matcher_.matches?(Proc.new { event_store.publish(actual = FooEvent.new) })

        expect(matcher_.failure_message).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including #{formatter[a: 2]})
        ] to be published

        i.e. expected event
          be an event FooEvent (with data including #{formatter[a: 2]})
        to be published, but it was not published

        There are events of correct type but with incorrect payload:
        1) #{actual.inspect}
            data diff:
            @@ -1 +1,2 @@
            +:a => 2,
        EOS
      end

      specify do
        expect(FooEvent).to receive(:new).and_return(actual = FooEvent.new)

        matcher_ = apply_matcher(matchers.an_event(FooEvent).with_data(a: 2)).in(aggregate)
        matcher_.matches?(Proc.new { aggregate.foo })

        expect(matcher_.failure_message).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including #{formatter[a: 2]})
        ] to be applied

        i.e. expected event
          be an event FooEvent (with data including #{formatter[a: 2]})
        to be applied, but it was not applied

        There are events of correct type but with incorrect payload:
        1) #{actual.inspect}
            data diff:
            @@ -1 +1,2 @@
            +:a => 2,
        EOS
      end

      specify do
        matcher_ = apply_matcher(matchers.an_event(FooEvent)).in(aggregate)
        matcher_.matches?(Proc.new {})

        expect(matcher_.failure_message_when_negated).to eq(<<~EOS)
        expected [
          be an event FooEvent
        ] not to be applied

        but the following was applied: [

        ]
        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new)
        matcher_ = matcher(matchers.an_event(FooEvent).with_data(a: 2))
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including #{formatter[a: 2]})
        ] to be published

        i.e. expected event
          be an event FooEvent (with data including #{formatter[a: 2]})
        to be published, but it was not published

        There are events of correct type but with incorrect payload:
        1) #{actual.inspect}
            data diff:
            @@ -1 +1,2 @@
            +:a => 2,
        EOS
      end

      specify do
        expect(FooEvent).to receive(:new).and_return(actual = FooEvent.new)

        aggregate.foo
        matcher_ = have_applied_matcher(matchers.an_event(FooEvent).with_data(a: 2))
        matcher_.matches?(aggregate)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including #{formatter[a: 2]})
        ] to be applied

        i.e. expected event
          be an event FooEvent (with data including #{formatter[a: 2]})
        to be applied, but it was not applied

        There are events of correct type but with incorrect payload:
        1) #{actual.inspect}
            data diff:
            @@ -1 +1,2 @@
            +:a => 2,
        EOS
      end

      specify do
        matcher_ = matcher
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected anything to be published
        EOS
      end

      specify do
        matcher_ = matcher
        matcher_.matches?(event_store)

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS)
        expected something to be published
        EOS
      end
    end
  end
end
