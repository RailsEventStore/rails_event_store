# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module RSpec
    ::RSpec.describe HavePublished do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        Client.new(
          mapper: Mappers::PipelineMapper.new(Mappers::Pipeline.new(to_domain_event: Transformations::IdentityMap.new)),
        )
      end

      def matcher(*expected)
        HavePublished.new(
          *expected,
          phraser: phraser,
          failure_message_formatter: RSpec.default_formatter.have_published(colorless_differ),
        )
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      def phraser
        Matchers::ListPhraser
      end

      specify { expect(event_store).not_to matcher }

      specify do
        event_store.publish(BarEvent.new)
        expect(event_store).to matcher
      end

      specify { expect(event_store).not_to matcher(matchers.an_event(FooEvent)) }

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
        event_store.publish(FooEvent.new, stream_name: "Foo")
        expect(event_store).to matcher(matchers.an_event(FooEvent)).in_streams("Foo")
      end

      specify do
        event_store.publish(FooEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).in_streams("Baz")
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Foo")
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).in_streams("Baz")
      end

      specify do
        event_store.publish(event = FooEvent.new, stream_name: "Foo")
        event_store.link(event.event_id, stream_name: "Bar")

        expect(event_store).to matcher(matchers.an_event(FooEvent)).in_streams(%w[Foo Bar])
      end

      specify do
        event_store.publish(event = FooEvent.new, stream_name: "Foo")
        event_store.link(event.event_id, stream_name: "Bar")

        expect(event_store).to matcher(matchers.an_event(FooEvent)).in_streams(%w[Foo Bar])
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Foo")

        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).in_streams(%w[Foo Bar])
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BazEvent.new)

        expect(event_store).to matcher(matchers.an_event(FooEvent), matchers.an_event(BazEvent))
      end

      specify do
        event_store.publish(FooEvent.new(data: { a: 1, b: 2 }))

        expect(event_store).to matcher(
          matchers.an_event(FooEvent).with_data(a: 1),
          matchers.an_event(FooEvent).with_data(b: 2),
        )
      end

      specify do
        event_store.publish(FooEvent.new)

        expect(event_store).not_to matcher(matchers.an_event(FooEvent), matchers.an_event(BazEvent))
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)

        expect(event_store).not_to matcher(matchers.an_event(FooEvent), matchers.an_event(BazEvent))
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)
        event_store.publish(BazEvent.new)

        expect(event_store).not_to matcher(matchers.an_event(FooEvent), matchers.an_event(BarEvent)).strict
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)

        expect(event_store).not_to matcher(matchers.an_event(BarEvent), matchers.an_event(FooEvent)).strict
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)

        expect(event_store).to matcher(matchers.an_event(FooEvent), matchers.an_event(BarEvent)).strict
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Foo")
        event_store.publish(BarEvent.new, stream_name: "Foo")
        event_store.publish(FooEvent.new, stream_name: "Bar")

        expect(event_store).to matcher(matchers.an_event(FooEvent), matchers.an_event(BarEvent)).strict.in_stream("Foo")
      end

      specify do
        event_store.publish(FooEvent.new(event_id: start_id = SecureRandom.uuid))
        event_store.publish(BarEvent.new)
        event_store.publish(BazEvent.new)

        expect(event_store).to matcher(matchers.an_event(BarEvent), matchers.an_event(BazEvent)).from(start_id)
      end

      specify do
        event_store.publish(FooEvent.new(event_id: start_id = SecureRandom.uuid))
        event_store.publish(BarEvent.new)
        event_store.publish(BazEvent.new)

        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).from(start_id)
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BazEvent.new)

        expect {
          expect(event_store).to matcher(matchers.an_event(FooEvent), matchers.an_event(BazEvent)).exactly(2).times
        }.to raise_error(NotSupported)
      end

      specify do
        expect { expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(0).times }.to raise_error(
          NotSupported,
        )
      end

      specify do
        expect { expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(-1).times }.to raise_error(
          NotSupported,
        )
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
        event_store.publish(actual = FooEvent.new, stream_name: "Foo")
        matcher_ = matcher(expected = matchers.an_event(BarEvent)).in_stream("Foo")
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [#{expected.inspect}] to be published in stream Foo, diff:
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
        event_store.publish(actual = FooEvent.new, stream_name: "Foo")
        matcher_ = matcher(expected = matchers.an_event(FooEvent)).in_stream("Foo")
        matcher_.matches?(event_store)

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS)
        expected [#{expected.inspect}] not to be published in stream Foo, diff:
        @@ -1,2 +1,2 @@
        -[#{actual.inspect}]
        +[#{expected.inspect}]
        EOS
      end

      specify { expect { HavePublished.new }.to raise_error(ArgumentError) }

      specify do
        matcher_ = matcher(matchers.an_event(FooEvent), matchers.an_event(BazEvent))
        expect(matcher_.description).to eq(
          "have published events that have to (be an event FooEvent and be an event BazEvent)",
        )
      end

      specify do
        matcher_ = matcher(FooEvent, BazEvent)
        expect(matcher_.description).to eq("have published events that have to (be a FooEvent and be a BazEvent)")
      end

      specify do
        old_formatter = RSpec.default_formatter
        RSpec.default_formatter = RSpec::StepByStepFailureMessageFormatter.new
        matcher_ = matcher(matchers.an_event(BarEvent))
        matcher_.matches?(event_store)

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
        expected [
          be an event BarEvent
        ] to be published

        i.e. expected event
          be an event BarEvent
        to be published, but there is no event with such type
        EOS
        RSpec.default_formatter = old_formatter
      end
    end
  end
end
