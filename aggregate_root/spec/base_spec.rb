require 'spec_helper'

module AggregateRoot
  describe Base do
    it "should be able to generate UUID if user won't provide it's own" do
      order1 = Order.new
      order2 = Order.new
      expect(order1.id).to_not eq(order2.id)
      expect(order1.id).to be_a(String)
    end

    it "should have ability to apply event on itself" do
      order = Order.new
      order_created = Orders::Events::OrderCreated.new

      order.apply(order_created)
      expect(order.unpublished_events).to eq([order_created])
    end

    it "should initialize default client if event_store not provided" do
      fake = double(:fake_event_store)
      AggregateRoot.configure do |config|
        config.default_event_store = fake
      end

      aggregate_repository = Repository.new
      expect(aggregate_repository.event_store).to eq(fake)
    end

    it "should receive a method call based on a default apply strategy" do
      order = Order.new
      order_created = Orders::Events::OrderCreated.new

      expect(order).to receive(:apply_orders_events_order_created).with(order_created)
      order.apply(order_created)

      expect(order).to receive(:apply_orders_events_order_created).with(order_created)
      order.apply_old_event(order_created)
    end

    it "should receive a method call based on a custom strategy" do
      order = OrderWithCustomStrategy.new
      order_created = Orders::Events::OrderCreated.new

      expect(order).to receive(:custom_order_processor).with(order_created)
      order.apply(order_created)

      expect(order).to receive(:custom_order_processor).with(order_created)
      order.apply_old_event(order_created)
    end
  end
end
