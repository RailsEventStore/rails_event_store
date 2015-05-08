require 'spec_helper.rb'

class Order
  include RailsEventStore::AggregateRoot

  def initialize(id = generate_uuid)
    @id = id
    @status = :draft
  end

  def apply_order_created
    @status = :created
  end

  attr_accessor :id, :status
end

class OrderCreated < RailsEventStore::Event
end

module RailsEventStore
  describe Client do
    it "should be able to generate UUID if user won't provide it's own" do
      order1 = Order.new
      order2 = Order.new
      expect(order1.id).to_not eq(order2.id)
      expect(order1.id).to be_a(String)
    end

    it "should have ability to apply event on itself" do
      order = Order.new
      order_created = OrderCreated.new

      expect(order.status).to eq(:draft)

      order.apply(order_created)
      expect(order.unpublished_events).to eq([order_created])

      expect(order.status).to eq(:created)
    end
  end
end
