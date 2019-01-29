require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe HavePublished do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        RailsEventStore::Client.new(
          repository: RailsEventStore::InMemoryRepository.new,
          mapper: RubyEventStore::Mappers::NullMapper.new
        )
      end

      def matcher(*expected)
        HavePublished.new(*expected, differ: colorless_differ, phraser: phraser)
      end

      def colorless_differ
        ::RailsEventStore::RSpec::SuperDiffStructuralDiffer.new(color: false)
      end

      def formatter
        ::RSpec::Support::ObjectFormatter.method(:format)
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
        event_store.publish(actual = FooEvent.new)
        _matcher = matcher(expected = matchers.an_event(BarEvent))
        _matcher.matches?(event_store)

        expect(_matcher.failure_message.to_s).to eq(<<~EOS)
          expected BarEvent to be published, diff:
          Differing arrays.

          Expected: [FooEvent, BarEvent]
            Actual: [FooEvent]

          Diff:

            [
              FooEvent
          -   BarEvent
            ]
        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new(data: {}))
        event_store.publish(actual = BarEvent.new(data: {some: 5}))
        _matcher = matcher(
            matchers.an_event(FooEvent).with_data(another: 5),
            matchers.an_event(BarEvent).with_data(other: 5)
        )
        _matcher.matches?(event_store)

        expect(_matcher.failure_message.to_s).to eq(<<~EOS)
          expected FooEvent to be published with:
          Differing hashes.

          Expected: { data: { another: 5 } }
            Actual: { data: {  } }

          Diff:

            {
              data: {
          -     another: 5
              }
            }
          expected BarEvent to be published with:
          Differing hashes.

          Expected: { data: { other: 5 } }
            Actual: { data: { some: 5 } }

          Diff:

            {
              data: {
          -     other: 5
          +     some: 5
              }
            }
        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new(data: {}))
        event_store.publish(actual = BarEvent.new(data: {some: 5}))
        _matcher = matcher(
            matchers.an_event(FooEvent).with_data(another: 5),
            matchers.an_event(BarEvent).with_data(some: 5)
        )
        _matcher.matches?(event_store)

        expect(_matcher.failure_message.to_s).to eq(<<~EOS)
          expected FooEvent to be published with:
          Differing hashes.

          Expected: { data: { another: 5 } }
            Actual: { data: {  } }

          Diff:

            {
              data: {
          -     another: 5
              }
            }

        EOS
      end

      specify do
        event_store.publish(actual = FooEvent.new)
        _matcher = matcher(expected = matchers.an_event(FooEvent))
        _matcher.matches?(event_store)

        expect(_matcher.failure_message_when_negated.to_s).to eq(<<~EOS)
          expected FooEvent not to be published, diff:
          Differing arrays.

          Expected: []
            Actual: [FooEvent]

          Diff:

            [
          +   FooEvent
            ]
        EOS
      end

      specify { expect{ HavePublished.new() }.to raise_error(ArgumentError) }

      specify do
        _matcher = matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
        expect(_matcher.description)
          .to eq("have published events: FooEvent, BazEvent")
      end

      specify do
        _matcher = matcher(
          FooEvent,
          BazEvent
        )
        expect(_matcher.description)
          .to eq("have published events: FooEvent, BazEvent")
      end
   end
  end
end
