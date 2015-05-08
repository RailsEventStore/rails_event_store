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
    describe AggregateRoot do
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

    describe Repositories::AggregateRepository do
      let(:event_store_repo) { EventInMemoryRepository.new }
      let(:event_store) { Client.new(event_store_repo) }

      it "should have ability to store aggregate" do
        aggregate_repository = Repositories::AggregateRepository.new(event_store)
        order = Order.new
        order_created = OrderCreated.new
        order.apply(order_created)

        aggregate_repository.store(order)

        expect(event_store_repo.get_all_events.count).to eq(1)
        expect(event_store_repo.get_all_events.first).to be_event({
          event_type: 'OrderCreated',
          stream: order.id,
          data: {}
        })
      end

      it "should initialize default RES client if event_store not provided" do
        expect(RailsEventStore)
        aggregate_repository = Repositories::AggregateRepository.new
        expect(aggregate_repository.event_store).to be_a(RailsEventStore::Client)
      end
    end
  end
end
