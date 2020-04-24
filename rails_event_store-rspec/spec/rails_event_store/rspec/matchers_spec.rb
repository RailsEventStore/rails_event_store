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
        event_store.publish(FooEvent.new)
        expect(event_store).to matchers.have_published(matchers.an_event(FooEvent))
      end

      specify do
        event_store = RailsEventStore::Client.new(repository: RailsEventStore::InMemoryRepository.new)
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)
        expect(event_store).to matchers.have_published(matchers.an_event(FooEvent), matchers.an_event(BarEvent))
      end

      specify do
        event_store = RailsEventStore::Client.new(repository: RailsEventStore::InMemoryRepository.new)
        event_store.publish(FooEvent.new)
        expect {
          event_store.publish(BarEvent.new)
        }.to publish(matchers.an_event(BarEvent)).in(event_store)
      end

      specify { expect(matchers.have_applied(matchers.an_event(FooEvent))).to be_an(HaveApplied) }

      specify do
        expect(matchers.have_applied(matchers.an_event(FooEvent)).description)
          .to eq("have applied events that have to (be an event FooEvent)")
      end

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

      specify do
        expect(matchers.publish).to be_a(Publish)
      end

      specify do
        aggregate = TestAggregate.new
        expect {
          aggregate.foo
        }.to apply(matchers.an_event(FooEvent)).in(aggregate)
      end

      specify do
        aggregate = TestAggregate.new
        expect {
          aggregate.foo
        }.not_to apply(matchers.an_event(BarEvent)).in(aggregate)
      end

      specify do
        expect(matchers.apply).to be_a(Apply)
      end
    end

    module Matchers
      ::RSpec.describe ListPhraser do
        let(:lister) { ListPhraser }

        specify do
          expect(lister.call(nil)).to eq('')
        end

        specify do
          expect(lister.call([nil])).to eq('')
        end

        specify do
          expect(lister.call([])).to eq('')
        end

        specify do
          expect(lister.call([FooEvent])).to eq('be a FooEvent')
        end

        specify do
          expect(lister.call([FooEvent, BarEvent])).to eq('be a FooEvent and be a BarEvent')
        end

        specify do
          expect(lister.call([FooEvent, BarEvent, BazEvent])).to eq('be a FooEvent, be a BarEvent and be a BazEvent')
        end

        specify do
          expect(lister.call([FooEvent, BarEvent, BazEvent, be_kind_of(Time)])).to eq('be a FooEvent, be a BarEvent, be a BazEvent and be a kind of Time')
        end
      end
    end
  end
end
