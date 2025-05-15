# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module RSpec
    ::RSpec.describe Matchers do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) { Client.new }

      specify { expect(matchers.be_an_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.be_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.an_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(FooEvent.new).to matchers.be_an_event(FooEvent) }
      specify { expect([FooEvent.new]).to include(matchers.an_event(FooEvent)) }

      describe "have_subscribed_to_events" do
        specify { expect(matchers.have_subscribed_to_events(FooEvent)).to be_an(HaveSubscribedToEvents) }

        specify { expect(matchers.have_subscribed_to_events(FooEvent, BarEvent)).to be_an(HaveSubscribedToEvents) }

        specify do
          handler = Handler.new
          event_store.subscribe(handler, to: [FooEvent])
          expect(handler).to matchers.have_subscribed_to_events(FooEvent).in(event_store)
          expect(handler).not_to matchers.have_subscribed_to_events(BarEvent).in(event_store)
        end
      end

      specify { expect(matchers.have_published(matchers.an_event(FooEvent))).to be_an(HavePublished) }

      specify do
        expect(matchers.have_published(matchers.an_event(FooEvent), matchers.an_event(BazEvent))).to be_an(
          HavePublished
        )
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
        expect { event_store.publish(BarEvent.new) }.to publish(matchers.an_event(BarEvent)).in(event_store)
      end

      specify { expect(matchers.have_applied(matchers.an_event(FooEvent))).to be_an(HaveApplied) }

      specify do
        expect(matchers.have_applied(matchers.an_event(FooEvent)).description).to eq(
          "have applied events that have to (be an event FooEvent)"
        )
      end

      specify do
        expect(matchers.have_applied(matchers.an_event(FooEvent), matchers.an_event(BazEvent))).to be_an(HaveApplied)
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

      specify { expect(matchers.publish).to be_a(Publish) }

      specify do
        aggregate = TestAggregate.new
        expect { aggregate.foo }.to apply(matchers.an_event(FooEvent)).in(aggregate)
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
        expect { aggregate.foo }.not_to apply(matchers.an_event(BarEvent)).in(aggregate)
      end

      specify { expect(matchers.apply).to be_a(Apply) }
    end

    module Matchers
      ::RSpec.describe ListPhraser do
        let(:lister) { ListPhraser }

        specify { expect(lister.call(nil)).to eq("") }

        specify { expect(lister.call([nil])).to eq("") }

        specify { expect(lister.call([])).to eq("") }

        specify { expect(lister.call([FooEvent])).to eq("be a FooEvent") }

        specify { expect(lister.call([FooEvent, BarEvent])).to eq("be a FooEvent and be a BarEvent") }

        specify do
          expect(lister.call([FooEvent, BarEvent, BazEvent])).to eq("be a FooEvent, be a BarEvent and be a BazEvent")
        end

        specify do
          expect(lister.call([FooEvent, BarEvent, BazEvent, be_a(Time)])).to eq(
            "be a FooEvent, be a BarEvent, be a BazEvent and be a kind of Time"
          )
        end
      end
    end
  end
end
