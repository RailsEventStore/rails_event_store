require 'spec_helper'

module AggregateRoot
  describe Repository do
    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }

    it "should use default event store when not given" do
      fake = double(:fake_event_store)
      AggregateRoot.configure do |config|
        config.default_event_store = fake
      end
      aggregate_repository = Repository.new
      expect(aggregate_repository.event_store).to eq(fake)
      expect(AggregateRoot.configuration.default_event_store).to eq(fake)
    end

    it "should use given event store" do
      aggregate_repository = Repository.new(event_store)
      expect(aggregate_repository.event_store).to eq(event_store)
    end

    it "by default there is no default event store" do
      aggregate_repository = Repository.new
      expect(aggregate_repository.event_store).to be_nil
    end

    it "should have ability to store & load aggregate" do
      aggregate_repository = Repository.new(event_store)
      order = Order.new
      order_created = Orders::Events::OrderCreated.new
      order_id = order.id
      order.apply(order_created)

      aggregate_repository.store(order)

      stream = event_store.read_stream_events_forward(order.id)
      expect(stream.count).to eq(1)
      expect(stream.first).to eq(order_created)

      order = Order.new(order_id)
      expect(order).to receive(:apply_orders_events_order_created).with(order_created)

      aggregate_repository.load(order)
      expect(order.unpublished_events).to be_empty
    end

    it "should recieve a method call on load based on a custom apply strategy" do
      aggregate_repository = Repository.new(event_store)
      order = OrderWithCustomStrategy.new
      order_created = Orders::Events::OrderCreated.new
      order_id = order.id
      order.apply(order_created)
      aggregate_repository.store(order)

      order = OrderWithCustomStrategy.new(order_id)
      expect(order).to receive(:custom_order_processor).with(order_created)

      aggregate_repository.load(order)
      expect(order.unpublished_events).to be_empty
    end
  end
end
