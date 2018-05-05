require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe HavePublished do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        RailsEventStore::Client.new(repository: RailsEventStore::InMemoryRepository.new)
      end

      def matcher(*expected)
        HavePublished.new(*expected, differ: colorless_differ, formatter: formatter)
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      def formatter
        ::RSpec::Support::ObjectFormatter.method(:format)
      end

      specify do
        expect(event_store).not_to matcher(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish_event(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish_event(BarEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish_event(FooEvent.new)
        event_store.publish_event(FooEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).exactly(1)
      end

      specify do
        event_store.publish_event(FooEvent.new)
        event_store.publish_event(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(2)
      end

      specify do
        event_store.publish_event(FooEvent.new)
        event_store.publish_event(BazEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(1)
      end

      specify do
        event_store.publish_event(FooEvent.new)
        event_store.publish_event(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(2).times
      end

      specify do
        event_store.publish_event(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).exactly(1).time
      end

      specify do
        event_store.publish_event(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent)).once
      end

      specify do
        event_store.publish_event(FooEvent.new)
        event_store.publish_event(FooEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).once
      end

      specify do
        event_store.publish_event(FooEvent.new, stream_name: "Foo")
        expect(event_store).to matcher(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish_event(FooEvent.new, stream_name: "Foo")
        expect(event_store).to matcher(matchers.an_event(FooEvent)).in_stream("Foo")
      end

      specify do
        event_store.publish_event(FooEvent.new, stream_name: "Foo")
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).in_stream("Baz")
      end

      specify do
        event_store.publish_event(FooEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent)).in_stream("Baz")
      end

      specify do
        event_store.publish_event(FooEvent.new)
        event_store.publish_event(BazEvent.new)

        expect(event_store).to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        event_store.publish_event(FooEvent.new)

        expect(event_store).not_to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        event_store.publish_event(FooEvent.new)
        event_store.publish_event(BarEvent.new)

        expect(event_store).not_to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        event_store.publish_event(FooEvent.new)
        event_store.publish_event(BazEvent.new)

        expect{
          expect(event_store).to matcher(
            matchers.an_event(FooEvent),
            matchers.an_event(BazEvent)
          ).exactly(2).times
        }.to raise_error(NotSupported)
      end

      specify do
        event_store.publish_event(FooEvent.new)
        _matcher = matcher(matchers.an_event(BarEvent))
        _matcher.matches?(event_store)

        expect(_matcher.failure_message.to_s).to include("] to be published")
        expect(_matcher.failure_message.to_s).to include("-[#<FooEvent")
        expect(_matcher.failure_message.to_s).to include("BeEvent")

        expect(_matcher.failure_message_when_negated.to_s).to include("] not to be published")
        expect(_matcher.failure_message_when_negated.to_s).to include("-[#<FooEvent")
        expect(_matcher.failure_message_when_negated.to_s).to include("BeEvent")
      end

      specify { expect{ HavePublished.new() }.to raise_error(ArgumentError) }

      specify do
        _matcher = matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
        expect(_matcher.description)
          .to eq("have published [be event FooEvent, be event BazEvent]")
      end

      specify do
        _matcher = matcher(
          FooEvent,
          BazEvent
        )
        expect(_matcher.description)
          .to eq("have published [FooEvent, BazEvent]")
      end
   end
  end
end
