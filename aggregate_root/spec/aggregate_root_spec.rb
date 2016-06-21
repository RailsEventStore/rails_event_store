require 'spec_helper'
require 'ruby_event_store'

class Order
  include AggregateRoot::Base

  def initialize(id = generate_uuid)
    self.id = id
    @status = :draft
  end

  private
  attr_accessor :status

  def apply_order_created(event)
    @status = :created
  end
end

class OrderCreated < RubyEventStore::Event
end

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
      order_created = OrderCreated.new

      order.apply(order_created)
      expect(order.unpublished_events).to eq([order_created])
    end
  end

  describe Repository do
    let(:event_store) { RubyEventStore::Facade.new(RubyEventStore::InMemoryRepository.new) }

    it "should have ability to store & load aggregate" do
      aggregate_repository = Repository.new(event_store)
      order = Order.new
      order_created = OrderCreated.new
      order_id = order.id
      order.apply(order_created)

      aggregate_repository.store(order)

      stream = event_store.read_stream_events_forward(order.id)
      expect(stream.count).to eq(1)
      expect(stream.first).to eq(order_created)

      order = Order.new(order_id)
      aggregate_repository.load(order)
      expect(order.unpublished_events).to be_empty
    end

    it "should initialize default client if event_store not provided" do
      fake = double(:fake_event_store)
      AggregateRoot.configure do |config|
        config.default_event_store = fake
      end

      aggregate_repository = Repository.new
      expect(aggregate_repository.event_store).to eq(fake)
    end
  end
end
