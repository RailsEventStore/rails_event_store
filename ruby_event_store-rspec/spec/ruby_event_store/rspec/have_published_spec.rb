require "spec_helper"

module RubyEventStore
  module RSpec
    ::RSpec.describe HavePublished do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        RubyEventStore::Client.new(
          repository: RubyEventStore::InMemoryRepository.new,
          mapper: RubyEventStore::Mappers::PipelineMapper.new(
            RubyEventStore::Mappers::Pipeline.new(to_domain_event: Transformations::IdentityMap.new)
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
        expect(event_store).not_to matcher(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish(BarEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(FooEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).exactly(1)
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(2)
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BazEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(1)
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(2).times
      end

      specify do
        event_store.publish(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(1).time
      end

      specify do
        event_store.publish(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).once
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(FooEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).once
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Foo")
        expect(event_store).to matcher(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Foo")
        expect(event_store).to matcher(matchers.an_event(FooEvent)).in_stream("Foo")
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Foo")
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).in_stream("Baz")
      end

      specify do
        event_store.publish(FooEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).in_stream("Baz")
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BazEvent.new)

        expect(event_store).to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        event_store.publish(FooEvent.new(data: { a: 1, b: 2}))

        expect(event_store).to matcher(
          matchers.an_event(FooEvent).with_data(a: 1),
          matchers.an_event(FooEvent).with_data(b: 2),
        )
      end

      specify do
        event_store.publish(FooEvent.new)

        expect(event_store).not_to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)

        expect(event_store).not_to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)
        event_store.publish(BazEvent.new)

        expect(event_store).not_to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BarEvent)
        ).strict
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)

        expect(event_store).not_to matcher(
          matchers.an_event(BarEvent),
          matchers.an_event(FooEvent)
        ).strict
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)

        expect(event_store).to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BarEvent)
        ).strict
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Foo")
        event_store.publish(BarEvent.new, stream_name: "Foo")
        event_store.publish(FooEvent.new, stream_name: "Bar")

        expect(event_store).to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BarEvent)
        ).strict.in_stream("Foo")
      end

      specify do
        event_store.publish(FooEvent.new(event_id: start_id = SecureRandom.uuid))
        event_store.publish(BarEvent.new)
        event_store.publish(BazEvent.new)

        expect(event_store).to matcher(
          matchers.an_event(BarEvent),
          matchers.an_event(BazEvent)
        ).from(start_id)
      end

      specify do
        event_store.publish(FooEvent.new(event_id: start_id = SecureRandom.uuid))
        event_store.publish(BarEvent.new)
        event_store.publish(BazEvent.new)

        expect(event_store).not_to matcher(
          matchers.an_event(FooEvent)
        ).from(start_id)
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BazEvent.new)

        expect{
          expect(event_store).to matcher(
            matchers.an_event(FooEvent),
            matchers.an_event(BazEvent)
          ).exactly(2).times
        }.to raise_error(NotSupported)
      end

      specify do
        expect{
          expect(event_store).to matcher(
            matchers.an_event(FooEvent),
          ).exactly(0).times
        }.to raise_error(NotSupported)
      end

      specify do
        expect{
          expect(event_store).to matcher(
            matchers.an_event(FooEvent),
          ).exactly(-1).times
        }.to raise_error(NotSupported)
      end

      specify do
        event_store.publish(actual = FooEvent.new)
        matcher_ = matcher(expected = matchers.an_event(BarEvent))
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
          expected [#{expected.inspect}] to be published, diff:
          @@ -1,2 +1,2 @@
          -[#{actual.inspect}]
          +[#{expected.inspect}]
        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new)
        matcher_ = matcher(expected = matchers.an_event(BarEvent))
        matcher_.matches?(event_store)

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS)
          expected [#{expected.inspect}] not to be published, diff:
          @@ -1,2 +1,2 @@
          -[#{actual.inspect}]
          +[#{expected.inspect}]
        EOS
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
        ).strict
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [#{expected.inspect}] to be published, diff:
        @@ -1,2 +1,2 @@
        -[#{actual.inspect}]
        +[#{expected.inspect}]
        EOS
      end

      specify { expect{ HavePublished.new() }.to raise_error(ArgumentError) }

      specify do
        matcher_ = matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
        expect(matcher_.description)
          .to eq("have published events that have to (be an event FooEvent and be an event BazEvent)")
      end

      specify do
        matcher_ = matcher(
          FooEvent,
          BazEvent
        )
        expect(matcher_.description)
          .to eq("have published events that have to (be a FooEvent and be a BazEvent)")
      end
    end
  end
end
