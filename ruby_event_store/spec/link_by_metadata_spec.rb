# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe LinkByMetadata do
    let(:event_store) { Client.new }

    specify "links to stream based on selected metadata" do
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :string))
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :float))
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :int))
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :missing))

      event_store.publish(ev = OrderCreated.new(metadata: { string: "city", float: 1.5, int: 2 }))

      expect(event_store.read.stream("$by_string_city").to_a).to eq([ev])
      expect(event_store.read.stream("$by_float_1.5").to_a).to eq([ev])
      expect(event_store.read.stream("$by_int_2").to_a).to eq([ev])

      expect(event_store.read.stream("$by_missing").to_a).to eq([])
      expect(event_store.read.stream("$by_missing_").to_a).to eq([])
      expect(event_store.read.stream("$by_missing_nil").to_a).to eq([])
    end

    specify "custom prefix" do
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :city, prefix: "sweet+"))

      event_store.publish(ev = OrderCreated.new(metadata: { city: "Paris" }))

      expect(event_store.read.stream("sweet+Paris").to_a).to eq([ev])
    end

    specify "explicitly passes array of ids instead of a single id" do
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :city))
      expect(event_store).to receive(:link).with(instance_of(Array), any_args)
      event_store.publish(OrderCreated.new(metadata: { city: "Paris" }))
    end
  end

  ::RSpec.describe LinkByCorrelationId do
    let(:event_store) { Client.new }
    let(:event) do
      OrderCreated.new.tap do |ev|
        ev.correlation_id = "COR"
        ev.causation_id = "CAU"
      end
    end

    specify "default prefix" do
      event_store.subscribe_to_all_events(LinkByCorrelationId.new(event_store: event_store))
      event_store.publish(event)
      expect(event_store.read.stream("$by_correlation_id_COR").to_a).to eq([event])
    end

    specify "custom prefix" do
      event_store.subscribe_to_all_events(LinkByCorrelationId.new(event_store: event_store, prefix: "c-"))
      event_store.publish(event)
      expect(event_store.read.stream("c-COR").to_a).to eq([event])
    end
  end

  ::RSpec.describe LinkByCausationId do
    let(:event_store) { Client.new }
    let(:event) do
      OrderCreated.new.tap do |ev|
        ev.correlation_id = "COR"
        ev.causation_id = "CAU"
      end
    end

    specify "default prefix" do
      event_store.subscribe_to_all_events(LinkByCausationId.new(event_store: event_store))
      event_store.publish(event)
      expect(event_store.read.stream("$by_causation_id_CAU").to_a).to eq([event])
    end

    specify "custom prefix" do
      event_store.subscribe_to_all_events(LinkByCausationId.new(event_store: event_store, prefix: "c-"))
      event_store.publish(event)
      expect(event_store.read.stream("c-CAU").to_a).to eq([event])
    end
  end

  ::RSpec.describe LinkByEventType do
    let(:event_store) { Client.new }
    let(:event) { OrderCreated.new }

    specify "default prefix" do
      event_store.subscribe_to_all_events(LinkByEventType.new(event_store: event_store))
      event_store.publish(event)
      expect(event_store.read.stream("$by_type_OrderCreated").to_a).to eq([event])
    end

    specify "custom prefix" do
      event_store.subscribe_to_all_events(LinkByEventType.new(event_store: event_store, prefix: "e-"))
      event_store.publish(event)
      expect(event_store.read.stream("e-OrderCreated").to_a).to eq([event])
    end

    specify "explicitly passes array of ids instead of a single id" do
      event_store.subscribe_to_all_events(LinkByEventType.new(event_store: event_store))
      expect(event_store).to receive(:link).with(instance_of(Array), any_args)
      event_store.publish(OrderCreated.new)
    end
  end
end
