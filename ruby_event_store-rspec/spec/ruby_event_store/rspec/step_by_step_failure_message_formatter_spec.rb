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
        HavePublished.new(*expected, differ: colorless_differ, phraser: phraser)
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      def phraser
        Matchers::ListPhraser
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(FooEvent.new)
        matcher_ = HavePublished.new(
          expected = matchers.an_event(FooEvent),
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        ).exactly(3).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
        to be published 3 times
        but was published 2 times
        EOS
      end

      specify do
        event_store.publish(FooEvent.new)
        matcher_ = HavePublished.new(
          expected = matchers.an_event(FooEvent),
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        ).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
        to be published 2 times
        but was published 1 times
        EOS
      end

      specify do
        event_store.publish(FooEvent.new(data: { foo: 123 }))
        matcher_ = HavePublished.new(
          expected = matchers.an_event(FooEvent).with_data({ foo: 124 }),
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        ).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
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
        matcher_ = HavePublished.new(
          expected = matchers.an_event(FooEvent).with_data({ foo: 124 }),
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        )
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
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
        matcher_ = HavePublished.new(
          expected = matchers.an_event(FooEvent).with_metadata({ foo: 124 }),
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        )
        matcher_.matches?(event_store)


        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
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
        matcher_ = HavePublished.new(
          expected = matchers.an_event(FooEvent).with_data({ foo: 123 }).strict,
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        )
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
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
        matcher_ = HavePublished.new(
          *(expected = [
            matchers.an_event(FooEvent).with_data({ a: 1 }),
            matchers.an_event(FooEvent).with_data({ b: 3 }),
          ]),
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        )
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event #{expected.inspect}
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
        matcher_ = HavePublished.new(
          expected = matchers.an_event(FooEvent),
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        )
        matcher_.matches?(event_store)


        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
        to be published, but there is no event with such type
        EOS
      end

      specify do
        event_store.publish(actual = BazEvent.new)
        matcher_ = HavePublished.new(
          expected = matchers.an_event(FooEvent),
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        ).exactly(2).times
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected event [#{expected.inspect}]
        to be published, but there is no event with such type
        EOS
      end

      specify do
        event_store.publish(actual = BazEvent.new)
        matcher_ = HavePublished.new(
          expected = matchers.an_event(FooEvent),
          differ: colorless_differ,
          phraser: phraser,
          failure_message_formatter: HavePublished::StepByStepFailureMessageFormatter
        ).strict
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [#{expected.inspect}] to be published, diff:
        @@ -1,2 +1,2 @@
        -[#{actual.inspect}]
        +[#{expected.inspect}]
        EOS
      end
    end
  end
end
