require 'spec_helper'

module RubyEventStore
  RSpec.describe LinkByMetadata do

    let(:event_store) do
      RubyEventStore::Client.new(repository: InMemoryRepository.new)
    end

    specify 'links to stream based on selected metadata' do
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :string))
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :float))
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :int))
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :missing))

      event_store.publish(ev = OrderCreated.new(metadata:{
        string: "city",
        float: 1.5,
        int: 2,
      }))

      expect(event_store.read.stream("$by_string_city").each.to_a).to eq([ev])
      expect(event_store.read.stream("$by_float_1.5").each.to_a).to   eq([ev])
      expect(event_store.read.stream("$by_int_2").each.to_a).to       eq([ev])

      expect(event_store.read.stream("$by_missing").each.to_a).to     eq([])
      expect(event_store.read.stream("$by_missing_").each.to_a).to    eq([])
      expect(event_store.read.stream("$by_missing_nil").each.to_a).to eq([])
    end

    specify 'links to stream based on selected metadata (proto)' do
      event_store = RubyEventStore::Client.new(
        mapper: RubyEventStore::Mappers::Protobuf.new,
        repository: InMemoryRepository.new
      )
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :city))
      ev = RubyEventStore::Proto.new(
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
        metadata: { city: "Chicago" }
      )
      event_store.publish(ev)

      expect(event_store.read.stream("$by_city_Chicago").each.to_a).to eq([ev])
    end

    specify "custom prefix" do
      event_store.subscribe_to_all_events(LinkByMetadata.new(
        event_store: event_store,
        key: :city,
        prefix: "sweet+")
      )

      event_store.publish(ev = OrderCreated.new(metadata:{
        city: "Paris",
      }))

      expect(event_store.read.stream("sweet+Paris").each.to_a).to eq([ev])
    end

    specify "explicitly passes array of ids instead of a single id" do
      event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :city))
      expect(event_store).to receive(:link).with(instance_of(Array), any_args)
      event_store.publish(ev = OrderCreated.new(metadata:{
        city: "Paris",
      }))
    end

  end

  RSpec.describe LinkByCorrelationId do
    let(:event_store) do
      RubyEventStore::Client.new(repository: InMemoryRepository.new)
    end
    let(:event) do
      OrderCreated.new.tap do |ev|
        ev.correlation_id = "COR"
        ev.causation_id   = "CAU"
      end
    end

    specify "default prefix" do
      event_store.subscribe_to_all_events(LinkByCorrelationId.new(event_store: event_store))
      event_store.publish(event)
      expect(event_store.read.stream("$by_correlation_id_COR").each.to_a).to eq([event])
    end

    specify "custom prefix" do
      event_store.subscribe_to_all_events(LinkByCorrelationId.new(event_store: event_store, prefix: "c-"))
      event_store.publish(event)
      expect(event_store.read.stream("c-COR").each.to_a).to eq([event])
    end
  end

  RSpec.describe LinkByCausationId do
    let(:event_store) do
      RubyEventStore::Client.new(repository: InMemoryRepository.new)
    end
    let(:event) do
      OrderCreated.new.tap do |ev|
        ev.correlation_id = "COR"
        ev.causation_id   = "CAU"
      end
    end

    specify "default prefix" do
      event_store.subscribe_to_all_events(LinkByCausationId.new(event_store: event_store))
      event_store.publish(event)
      expect(event_store.read.stream("$by_causation_id_CAU").each.to_a).to eq([event])
    end

    specify "custom prefix" do
      event_store.subscribe_to_all_events(LinkByCausationId.new(event_store: event_store, prefix: "c-"))
      event_store.publish(event)
      expect(event_store.read.stream("c-CAU").each.to_a).to eq([event])
    end
  end

  RSpec.describe LinkByEventType do
    let(:event_store) do
      RubyEventStore::Client.new(repository: InMemoryRepository.new)
    end
    let(:event) { OrderCreated.new }

    specify "default prefix" do
      event_store.subscribe_to_all_events(LinkByEventType.new(event_store: event_store))
      event_store.publish(event)
      expect(event_store.read.stream("$by_type_OrderCreated").each.to_a).to eq([event])
    end

    specify "custom prefix" do
      event_store.subscribe_to_all_events(LinkByEventType.new(event_store: event_store, prefix: "e-"))
      event_store.publish(event)
      expect(event_store.read.stream("e-OrderCreated").each.to_a).to eq([event])
    end

    specify "explicitly passes array of ids instead of a single id" do
      event_store.subscribe_to_all_events(LinkByEventType.new(event_store: event_store))
      expect(event_store).to receive(:link).with(instance_of(Array), any_args)
      event_store.publish(ev = OrderCreated.new())
    end
  end

end

