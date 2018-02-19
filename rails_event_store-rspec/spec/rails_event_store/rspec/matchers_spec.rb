require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe Matchers do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }

      specify { expect(matchers.be_an_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.be_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.an_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(FooEvent.new).to matchers.be_an_event(FooEvent) }
      specify { expect([FooEvent.new]).to include(matchers.an_event(FooEvent)) }

      specify { expect(matchers.have_published(matchers.an_event(FooEvent))).to be_an(HavePublished) }

      specify do
        expect(matchers.have_published(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )).to be_an(HavePublished)
      end

      specify do
        event_store = RailsEventStore::Client.new(repository: RailsEventStore::InMemoryRepository.new)
        event_store.publish_event(FooEvent.new)
        expect(event_store).to matchers.have_published(matchers.an_event(FooEvent))
      end

      specify do
        event_store = RailsEventStore::Client.new(repository: RailsEventStore::InMemoryRepository.new)
        event_store.publish_event(FooEvent.new)
        event_store.publish_event(BarEvent.new)
        expect(event_store).to matchers.have_published(matchers.an_event(FooEvent), matchers.an_event(BarEvent))
      end

      specify { expect(matchers.have_applied(matchers.an_event(FooEvent))).to be_an(HaveApplied) }

      specify do
        expect(matchers.have_applied(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )).to be_an(HaveApplied)
      end

      specify do
        aggregate_root = TestAggregate.new
        aggregate_root.foo
        expect(aggregate_root).to matchers.have_applied(matchers.an_event(FooEvent))
      end

      specify do
        aggregate_root = TestAggregate.new
        aggregate_root.foo
        aggregate_root.bar
        expect(aggregate_root).to matchers.have_applied(matchers.an_event(FooEvent), matchers.an_event(BarEvent))
      end
    end
  end
end
