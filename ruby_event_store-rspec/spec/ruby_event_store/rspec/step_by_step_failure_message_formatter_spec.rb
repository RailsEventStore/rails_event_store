require "spec_helper"

module RubyEventStore
  module RSpec
    ::RSpec.describe HavePublished::StepByStepFailureMessageFormatter do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        RubyEventStore::Client.new(
          repository: RubyEventStore::InMemoryRepository.new,
          mapper: RubyEventStore::Mappers::PipelineMapper.new(
            RubyEventStore::Mappers::Pipeline.new(to_domain_event: IdentityMapTransformation.new)
          )
        )
      end

      def matcher(*expected)
        HavePublished.new(*expected, differ: colorless_differ, phraser: phraser, failure_message_formatter: failure_message_formatter)
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      def phraser
        Matchers::ListPhraser
      end

      def failure_message_formatter
        HavePublished::StepByStepFailureMessageFormatter
      end

      def fallback_formatter
        HavePublished::CrudeFailureMessageFormatter
      end

      def matcher_with_fallback_formatter(*expected)
        HavePublished.new(*expected, differ: colorless_differ, phraser: phraser, failure_message_formatter: fallback_formatter)
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(FooEvent.new)
        matcher_ = matcher(expected = matchers.an_event(FooEvent)).exactly(3).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
        to be published 3 times
        but was published 2 times
        EOS
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(FooEvent.new)
        matcher_ = matcher(expected = matchers.an_event(FooEvent)).exactly(3).times.strict
        matcher_.matches?(event_store)

        fallback_matcher_ = matcher_with_fallback_formatter(expected).exactly(3).times.strict
        fallback_matcher_.matches?(event_store)
        expect(matcher_.failure_message.to_s).to eq(fallback_matcher_.failure_message.to_s)
      end

      specify do
        event_store.publish(FooEvent.new)
        matcher_ = matcher(expected = matchers.an_event(FooEvent)).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
        to be published 2 times
        but was published 1 times
        EOS
      end

      specify do
        event_store.publish(FooEvent.new(data: { foo: 123 }))
        matcher_ = matcher(expected = matchers.an_event(FooEvent).with_data({ foo: 124 })).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including {:foo=>124})
        ] to be published

        i.e. expected event #{expected.inspect}
        to be published, but it was not published

        there is an event of correct type but with incorrect payload:
        data diff:
        @@ -1,2 +1,2 @@
        -:foo => 123,
        +:foo => 124,

        EOS
      end

      specify do
        event_store.publish(FooEvent.new(data: { foo: 123 }))
        matcher_ = matcher(expected = matchers.an_event(FooEvent).with_data({ foo: 124 }))
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including {:foo=>124})
        ] to be published

        i.e. expected event #{expected.inspect}
        to be published, but it was not published

        there is an event of correct type but with incorrect payload:
        data diff:
        @@ -1,2 +1,2 @@
        -:foo => 123,
        +:foo => 124,

        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new(metadata: { foo: 123 }))
        matcher_ = matcher(expected = matchers.an_event(FooEvent).with_metadata({ foo: 124 }))
        matcher_.matches?(event_store)


        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with metadata including {:foo=>124})
        ] to be published

        i.e. expected event #{expected.inspect}
        to be published, but it was not published

        there is an event of correct type but with incorrect payload:
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
        event_store.publish(FooEvent.new(data: { foo: 123, bar: 20 }))
        matcher_ = matcher(expected = matchers.an_event(FooEvent).with_data({ foo: 123 }).strict)
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data matching {:foo=>123})
        ] to be published

        i.e. expected event #{expected.inspect}
        to be published, but it was not published

        there is an event of correct type but with incorrect payload:
        data diff:
        @@ -1,3 +1,2 @@
        -:bar => 20,
         :foo => 123,

        EOS
      end

      specify do
        event_store.publish(FooEvent.new(data: { a: 1, b: 2 }))
        expected = [
          matchers.an_event(FooEvent).with_data({ a: 1 }),
          matchers.an_event(FooEvent).with_data({ b: 3 }),
        ]
        matcher_ = matcher(*expected)
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event FooEvent (with data including {:a=>1})
          be an event FooEvent (with data including {:b=>3})
        ] to be published

        i.e. expected event #{expected[1].inspect}
        to be published, but it was not published

        there is an event of correct type but with incorrect payload:
        data diff:
        @@ -1,3 +1,2 @@
        -:a => 1,
        -:b => 2,
        +:b => 3,

        EOS
      end

      specify do
        event_store.publish(actual = BazEvent.new)
        matcher_ = matcher(expected = matchers.an_event(FooEvent))
        matcher_.matches?(event_store)


        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
        to be published, but there is no event with such type
        EOS
      end

      specify do
        event_store.publish(actual = BazEvent.new)
        matcher_ = matcher(expected = matchers.an_event(FooEvent)).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
        to be published, but there is no event with such type
        EOS
      end

      specify do
        event_store.publish(actual = BazEvent.new)
        matcher_ = matcher(expected = matchers.an_event(FooEvent)).strict
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [#{expected.inspect}] to be published, diff:
        @@ -1,2 +1,2 @@
        -[#{actual.inspect}]
        +[#{expected.inspect}]
        EOS
      end

      specify do
        event_store.publish(FooEvent.new)
        matcher_ = matcher(expected = matchers.an_event(FooEvent))
        matcher_.matches?(event_store)

        fallback_matcher_ = matcher_with_fallback_formatter(expected)
        fallback_matcher_.matches?(event_store)
        expect(matcher_.failure_message_when_negated.to_s).to eq(fallback_matcher_.failure_message_when_negated.to_s)
      end

      specify do
        event_store.publish(FooEvent.new(data: { a: 1 }))
        event_store.publish(FooEvent.new(data: { a: 1 }))
        event_store.publish(FooEvent.new(data: { a: 2 }))
        expected = [
          matchers.an_event(FooEvent).with_data(a: 1),
          matchers.an_event(BarEvent),
        ]
        matcher_ = matcher(*expected)
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event #{expected.inspect}
        to be published, but there is no event with such type
        EOS
      end
    end
  end
end
