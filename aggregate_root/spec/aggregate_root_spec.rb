require 'spec_helper'

module AggregateRoot
  describe 'base scenarios' do
    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }

    it "should have ability to apply event on itself" do
      order = Order.new
      order_created = Orders::Events::OrderCreated.new

      order.apply(order_created)
      expect(order.__send__("unpublished_events")).to eq([order_created])
    end

    it "should work with provided event_store" do
      AggregateRoot.configure do |config|
        config.default_event_store = double(:some_other_event_store)
      end

      stream = "any-order-stream"
      order = Order.new.load(stream, event_store: event_store)
      order_created = Orders::Events::OrderCreated.new
      order.apply(order_created)
      order.store(stream, event_store: event_store)

      expect(event_store.read_stream_events_forward(stream)).to eq [order_created]

      restored_order = Order.new.load(stream, event_store: event_store)
      expect(restored_order.status).to eq :created
      order_expired = Orders::Events::OrderExpired.new
      restored_order.apply(order_expired)
      restored_order.store(stream, event_store: event_store)

      expect(event_store.read_stream_events_forward(stream)).to eq [order_created, order_expired]

      restored_again_order = Order.new.load(stream, event_store: event_store)
      expect(restored_again_order.status).to eq :expired
    end

    it "should use default client if event_store not provided" do
      AggregateRoot.configure do |config|
        config.default_event_store = event_store
      end

      stream = "any-order-stream"
      order = Order.new.load(stream)
      order_created = Orders::Events::OrderCreated.new
      order.apply(order_created)
      order.store(stream)

      expect(event_store.read_stream_events_forward(stream)).to eq [order_created]

      restored_order = Order.new.load(stream)
      expect(restored_order.status).to eq :created
      order_expired = Orders::Events::OrderExpired.new
      restored_order.apply(order_expired)
      restored_order.store(stream)

      expect(event_store.read_stream_events_forward(stream)).to eq [order_created, order_expired]

      restored_again_order = Order.new.load(stream)
      expect(restored_again_order.status).to eq :expired
    end

    it "if loaded from some stream should store to the same stream is no other stream specified" do
      AggregateRoot.configure do |config|
        config.default_event_store = event_store
      end

      stream = "any-order-stream"
      order = Order.new.load(stream)
      order_created = Orders::Events::OrderCreated.new
      order.apply(order_created)
      order.store

      expect(event_store.read_stream_events_forward(stream)).to eq [order_created]
    end

    it "should receive a method call based on a default apply strategy" do
      order = Order.new
      order_created = Orders::Events::OrderCreated.new

      order.apply(order_created)
      expect(order.status).to eq :created
    end

    it "should receive a method call based on a custom strategy" do
      order = OrderWithCustomStrategy.new
      order_created = Orders::Events::OrderCreated.new

      order.apply(order_created)
      expect(order.status).to eq :created
    end
  end
end
