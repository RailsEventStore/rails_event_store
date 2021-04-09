require "spec_helper"

module RubyEventStore
  module RSpec
    ::RSpec.describe Matchers do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
      end

      specify { expect(matchers.be_an_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.be_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.an_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(FooEvent.new).to matchers.be_an_event(FooEvent) }
      specify { expect([FooEvent.new]).to include(matchers.an_event(FooEvent)) }

      describe "have_subscribed_to_events" do
        specify do
          expect(matchers.have_subscribed_to_events(FooEvent)).to be_an(HaveSubscribedToEvents)
        end

        specify do
          expect(matchers.have_subscribed_to_events(FooEvent, BarEvent)).to be_an(HaveSubscribedToEvents)
        end

        specify do
          event_store.subscribe(Handler, to: [FooEvent])
          expect(Handler).to matchers.have_subscribed_to_events(FooEvent).in(event_store)
          expect(Handler).not_to matchers.have_subscribed_to_events(BarEvent).in(event_store)
        end
      end

      specify { expect(matchers.have_published(matchers.an_event(FooEvent))).to be_an(HavePublished) }

      specify do
        expect(matchers.have_published(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )).to be_an(HavePublished)
      end

      specify do
        event_store.publish(FooEvent.new)
        expect(event_store).to matchers.have_published(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(BarEvent.new)
        expect(event_store).to matchers.have_published(matchers.an_event(FooEvent), matchers.an_event(BarEvent))
      end

      specify do
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
        expect(RSpec.default_formatter).to receive(:apply).with(kind_of(::RSpec::Support::Differ)).and_call_original
        aggregate = TestAggregate.new
        matcher = apply(matchers.an_event(FooEvent).with_data(a: 1)).in(aggregate)
        matcher.matches?(Proc.new { aggregate.foo })
        expect(matcher.failure_message.to_s).not_to be_empty
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
