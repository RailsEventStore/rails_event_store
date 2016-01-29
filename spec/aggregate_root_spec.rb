require 'spec_helper.rb'

class Order
  include RailsEventStore::AggregateRoot

  def initialize(id = generate_uuid)
    @id = id
    @status = :draft
  end

  attr_reader :id
  private
  attr_accessor :status

  def apply_order_created(event)
    @status = :created
  end

  def apply_order_completed(event)
    @status = :completed
  end
end

class OrderCreated < RailsEventStore::Event
end
class OrderCompleted < RailsEventStore::Event
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

        order.apply(order_created)
        expect(order.unpublished_events).to eq([order_created])
      end
    end

    describe Repositories::AggregateRepository do
      let(:event_store_repo) { EventInMemoryRepository.new }
      let(:event_store) { Client.new(event_store_repo) }

      it "should have ability to store & load aggregate" do
        aggregate_repository = Repositories::AggregateRepository.new(event_store)
        order = Order.new
        order_created = OrderCreated.new
        order_id = order.id
        order.apply(order_created)

        aggregate_repository.store(order)


        stream = event_store_repo.load_all_events_forward(order.id)
        expect(stream.count).to eq(1)
        expect(stream.first).to be_event({
          event_type: 'OrderCreated',
          data: {}
        })

        order = Order.new(order_id)
        aggregate_repository.load(order)
        expect(order.unpublished_events).to be_empty
      end

      it "should initialize default RES client if event_store not provided" do
        aggregate_repository = Repositories::AggregateRepository.new
        expect(aggregate_repository.event_store).to be_a(RailsEventStore::Client)
      end

      it 'should allow update with 2 or more event (checking expected version)' do
        aggregate_repository = Repositories::AggregateRepository.new(event_store)
        order = Order.new
        order_id = order.id
        order.apply(order_created = OrderCreated.new)
        order.apply(order_completed = OrderCompleted.new)
        aggregate_repository.store(order)

        reloaded_order = Order.new(order_id)
        aggregate_repository.load(reloaded_order)
        expect(reloaded_order.version).to eq(order_completed.event_id)
      end

      it 'should fail when aggregate stream has been modified' do
        aggregate_repository = Repositories::AggregateRepository.new(event_store)
        order = Order.new
        order_created = OrderCreated.new
        order_id = order.id
        order.apply(order_created)
        aggregate_repository.store(order)

        order1 = Order.new(order_id)
        aggregate_repository.load(order1)
        order2 = Order.new(order_id)
        aggregate_repository.load(order2)
        order1.apply(OrderCompleted.new)
        order2.apply(OrderCompleted.new)
        aggregate_repository.store(order1)

        expect { aggregate_repository.store(order2) }.to raise_error(AggregateRoot::HasBeenChanged)
      end
    end
  end
end
