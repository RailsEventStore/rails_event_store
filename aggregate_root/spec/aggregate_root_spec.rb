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

  def apply_strategy
    @apply_strategy = AggregateRoot::DefaultApplyStrategy.new
  end

  def apply_events_order_created(event)
    @status = :created
  end
end

module Events
  OrderCreated = Class.new(RubyEventStore::Event)
end

class CustomOrderApplyStrategy
  def call(aggregate, event)
    case event.class.object_id
    when Events::OrderCreated.object_id
      aggregate.method(:custom_order_processor).call(event)
    else
      aggregate.method(:process_unhandled_event).call(event)
    end
  end
end

class OrderWithCustomStrategy
  include AggregateRoot::Base

  def initialize(id = generate_uuid)
    self.id = id
    @status = :draft
  end

  def apply_strategy
    @apply_strategy ||= CustomOrderApplyStrategy.new
  end

  private
  attr_accessor :status, :other_value

  def custom_order_processor(event)
    @status = :created
  end

  def process_unhandled_event(event)
  end
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
      order_created = Events::OrderCreated.new

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
      order_created = Events::OrderCreated.new

      expect(order).to receive(:apply_events_order_created).with(order_created)
      order.apply(order_created)

      expect(order).to receive(:apply_events_order_created).with(order_created)
      order.apply_old_event(order_created)
    end

    it "should receive a method call based on a custom strategy" do
      order = OrderWithCustomStrategy.new
      order_created = Events::OrderCreated.new

      expect(order).to receive(:custom_order_processor).with(order_created)
      order.apply(order_created)

      expect(order).to receive(:custom_order_processor).with(order_created)
      order.apply_old_event(order_created)
    end
  end

  describe Repository do
    let(:event_store) { RubyEventStore::Client.new(RubyEventStore::InMemoryRepository.new) }

    it "should have ability to store & load aggregate" do
      aggregate_repository = Repository.new(event_store)
      order = Order.new
      order_created = Events::OrderCreated.new
      order_id = order.id
      order.apply(order_created)

      aggregate_repository.store(order)

      stream = event_store.read_stream_events_forward(order.id)
      expect(stream.count).to eq(1)
      expect(stream.first).to eq(order_created)

      order = Order.new(order_id)
      expect(order).to receive(:apply_events_order_created).with(order_created)

      aggregate_repository.load(order)
      expect(order.unpublished_events).to be_empty
    end

    it "should recieve a method call on load based on a custom apply strategy" do
      aggregate_repository = Repository.new(event_store)
      order = OrderWithCustomStrategy.new
      order_created = Events::OrderCreated.new
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
