require 'spec_helper'
require 'action_controller/railtie'

module RailsEventStore
  RSpec.describe LinkByMetadata do
    let(:event_store) { RailsEventStore::Client.new }
    let(:application) { instance_double(Rails::Application) }
    let(:config)      { FakeConfiguration.new }

    before do
      allow(Rails).to       receive(:application).and_return(application)
      allow(application).to receive(:config).and_return(config)
      Rails.configuration.event_store = event_store
    end

    specify "links" do
      event_store.subscribe_to_all_events(LinkByMetadata.new(key: :city))
      event_store.publish(ev = OrderCreated.new(metadata:{
        city: "Paris",
      }))
      expect(event_store.read.stream("$by_city_Paris").to_a).to eq([ev])
    end

    specify "defaults to Rails.configuration.event_store and passes rest of options" do
      event_store.subscribe_to_all_events(LinkByMetadata.new(
        key: :city,
        prefix: "sweet+")
      )
      event_store.publish(ev = OrderCreated.new(metadata:{
        city: "Paris",
      }))
      expect(event_store.read.stream("sweet+Paris").to_a).to eq([ev])
    end

  end

  RSpec.describe LinkByCorrelationId do
    let(:event_store) { RailsEventStore::Client.new }
    let(:event) do
      OrderCreated.new.tap do |ev|
        ev.correlation_id = "COR"
        ev.causation_id   = "CAU"
      end
    end
    let(:application) { instance_double(Rails::Application) }
    let(:config)      { FakeConfiguration.new }

    before do
      allow(Rails).to       receive(:application).and_return(application)
      allow(application).to receive(:config).and_return(config)
      Rails.configuration.event_store = event_store
    end

    specify "links" do
      event_store.subscribe_to_all_events(LinkByCorrelationId.new)
      event_store.publish(event)
      expect(event_store.read.stream("$by_correlation_id_COR").to_a).to eq([event])
    end

    specify "defaults to Rails.configuration.event_store and passes rest of options" do
      event_store.subscribe_to_all_events(LinkByCorrelationId.new(prefix: "sweet+"))
      event_store.publish(event)
      expect(event_store.read.stream("sweet+COR").to_a).to eq([event])
    end
  end

  RSpec.describe LinkByCausationId do
    let(:event_store) { RailsEventStore::Client.new }
    let(:event) do
      OrderCreated.new.tap do |ev|
        ev.correlation_id = "COR"
        ev.causation_id   = "CAU"
      end
    end
    let(:application) { instance_double(Rails::Application) }
    let(:config)      { FakeConfiguration.new }

    before do
      allow(Rails).to       receive(:application).and_return(application)
      allow(application).to receive(:config).and_return(config)
      Rails.configuration.event_store = event_store
    end

    specify "links" do
      event_store.subscribe_to_all_events(LinkByCausationId.new)
      event_store.publish(event)
      expect(event_store.read.stream("$by_causation_id_CAU").to_a).to eq([event])
    end

    specify "defaults to Rails.configuration.event_store and passes rest of options" do
      event_store.subscribe_to_all_events(LinkByCausationId.new(prefix: "sweet+"))
      event_store.publish(event)
      expect(event_store.read.stream("sweet+CAU").to_a).to eq([event])
    end
  end

  RSpec.describe LinkByEventType do
    let(:event_store) { RailsEventStore::Client.new }
    let(:event) { OrderCreated.new }
    let(:application) { instance_double(Rails::Application) }
    let(:config)      { FakeConfiguration.new }

    before do
      allow(Rails).to       receive(:application).and_return(application)
      allow(application).to receive(:config).and_return(config)
      Rails.configuration.event_store = event_store
    end

    specify "default prefix" do
      event_store.subscribe_to_all_events(LinkByEventType.new)
      event_store.publish(event)
      expect(event_store.read.stream("$by_type_OrderCreated").to_a).to eq([event])
    end

    specify "custom prefix" do
      event_store.subscribe_to_all_events(LinkByEventType.new(prefix: "e-"))
      event_store.publish(event)
      expect(event_store.read.stream("e-OrderCreated").to_a).to eq([event])
    end
  end

end
