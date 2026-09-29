# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe AsyncSubscriptions do
      let(:subscriptions) { AsyncSubscriptions.new(dispatcher: RubyEventStore::SyncScheduler.new) }

      specify "registers a subscriber under its class name for every given topic" do
        handler = recording_handler("OrderReport")

        subscriptions.add(handler, %w[OrderPlaced OrderCancelled])

        expect(subscriptions.names_for("OrderPlaced")).to eq(["OrderReport"])
        expect(subscriptions.names_for("OrderCancelled")).to eq(["OrderReport"])
        expect(subscriptions.resolve("OrderPlaced", "OrderReport")).to equal(handler)
      end

      specify "lists every subscriber of a topic, each once" do
        subscriptions.add(recording_handler("First"), ["OrderPlaced"])
        subscriptions.add(recording_handler("Second"), ["OrderPlaced"])
        subscriptions.add(First, ["OrderPlaced"])

        expect(subscriptions.names_for("OrderPlaced")).to eq(%w[First Second])
      end

      specify "knows no subscribers for an unknown topic, without registering the topic" do
        expect(subscriptions.names_for("Unknown")).to eq([])
        expect(subscriptions.resolve("Unknown", "Kernel")).to be_nil
        expect(subscriptions.instance_variable_get(:@subscribers)).to be_empty
      end

      specify "resolves only a name registered for that very topic, never an arbitrary constant" do
        subscriptions.add(recording_handler("OrderReport"), ["OrderPlaced"])

        expect(subscriptions.resolve("OrderCancelled", "OrderReport")).to be_nil
        expect(subscriptions.resolve("OrderPlaced", "Kernel")).to be_nil
      end

      specify "rejects a subscriber that is not a class" do
        expect { subscriptions.add(->(_event) {}, ["OrderPlaced"]) }.to raise_error(
          ArgumentError,
          /\Aasync subscriber must be a named class, got #<Proc/,
        )
      end

      specify "names the offending subscriber by its inspection" do
        expect { subscriptions.add("OrderReport", ["OrderPlaced"]) }.to raise_error(
          ArgumentError,
          'async subscriber must be a named class, got "OrderReport"',
        )
      end

      specify "rejects an anonymous class" do
        handler = Class.new { def self.call(_event) = nil }

        expect { subscriptions.add(handler, ["OrderPlaced"]) }.to raise_error(ArgumentError, /must be a named class/)
      end

      specify "rejects a subscriber the dispatcher does not accept" do
        stub_const("NotCallable", Class.new)

        expect { subscriptions.add(NotCallable, ["OrderPlaced"]) }.to raise_error(
          RubyEventStore::InvalidHandler,
          "Handler NotCallable is invalid for dispatcher #{subscriptions.send(:dispatcher)}",
        )
        expect(subscriptions.names_for("OrderPlaced")).to eq([])
      end

      specify "dispatches through the dispatcher" do
        dispatcher = double(:dispatcher, verify: true)
        allow(dispatcher).to receive(:call)
        subscriptions = AsyncSubscriptions.new(dispatcher: dispatcher)
        subscriber, event, record = double(:subscriber), double(:event), double(:record)

        subscriptions.dispatch(subscriber, event, record)

        expect(dispatcher).to have_received(:call).with(subscriber, event, record)
      end
    end
  end
end
