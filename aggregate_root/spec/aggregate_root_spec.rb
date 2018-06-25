require 'spec_helper'

RSpec.describe AggregateRoot do
  let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }

  it "should have ability to apply event on itself" do
    order = Order.new
    order_created = Orders::Events::OrderCreated.new

    expect(order).to receive(:"apply_order_created").with(order_created).and_call_original
    order.apply(order_created)
    expect(order.status).to eq :created
    expect(order.unpublished_events.to_a).to eq([order_created])
  end

  it "brand new aggregate does not have any unpublished events" do
    order = Order.new
    expect(order.unpublished_events.to_a).to be_empty
  end

  it "should have no unpublished events when loaded" do
    stream = "any-order-stream"
    order_created = Orders::Events::OrderCreated.new
    event_store.publish(order_created, stream_name: stream)

    order = Order.new.load(stream, event_store: event_store)
    expect(order.status).to eq :created
    expect(order.unpublished_events.to_a).to be_empty
  end

  it "should publish all unpublished events on store" do
    stream = "any-order-stream"
    order_created = Orders::Events::OrderCreated.new
    order_expired = Orders::Events::OrderExpired.new
    order_complicated = Orders::Events::OrderA1BcdEFghI2Jz.new

    order = Order.new
    order.apply(order_created)
    order.apply(order_expired)
    order.apply(order_complicated)
    expect(event_store).not_to receive(:publish).with(kind_of(Enumerator), any_args)
    expect(event_store).to receive(:publish).with([order_created, order_expired, order_complicated], stream_name: stream, expected_version: -1).and_call_original
    order.store(stream, event_store: event_store)
    expect(order.unpublished_events.to_a).to be_empty
  end

  it "updates aggregate stream position and uses it in subsequent publish call as expected_version" do
    stream = "any-order-stream"
    order_created = Orders::Events::OrderCreated.new

    order = Order.new
    order.apply(order_created)
    expect(event_store).to receive(:publish).with([order_created], stream_name: stream, expected_version: -1).and_call_original
    order.store(stream, event_store: event_store)

    order_expired = Orders::Events::OrderExpired.new
    order.apply(order_expired)
    expect(event_store).to receive(:publish).with([order_expired], stream_name: stream, expected_version: 0).and_call_original
    order.store(stream, event_store: event_store)
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

    expect(event_store.read.stream(stream).each.to_a).to eq [order_created]

    restored_order = Order.new.load(stream, event_store: event_store)
    expect(restored_order.status).to eq :created
    order_expired = Orders::Events::OrderExpired.new
    restored_order.apply(order_expired)
    restored_order.store(stream, event_store: event_store)

    expect(event_store.read.stream(stream).each.to_a).to eq [order_created, order_expired]

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

    expect(event_store.read.stream(stream).each.to_a).to eq [order_created]

    restored_order = Order.new.load(stream)
    expect(restored_order.status).to eq :created
    order_expired = Orders::Events::OrderExpired.new
    restored_order.apply(order_expired)
    restored_order.store(stream)

    expect(event_store.read.stream(stream).each.to_a).to eq [order_created, order_expired]

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

    expect(event_store.read.stream(stream).each.to_a).to eq [order_created]
  end

  it "should receive a method call based on a default apply strategy" do
    order = Order.new
    order_created = Orders::Events::OrderCreated.new

    order.apply(order_created)
    expect(order.status).to eq :created
  end

  it "should raise error for missing apply method based on a default apply strategy" do
    order = Order.new
    spanish_inquisition = Orders::Events::SpanishInquisition.new
    expect{ order.apply(spanish_inquisition) }.to raise_error(AggregateRoot::MissingHandler, "Missing handler method apply_spanish_inquisition on aggregate Order")
  end

  it "should ignore missing apply method based on a default non-strict apply strategy" do
    order = OrderWithNonStrictApplyStrategy.new
    spanish_inquisition = Orders::Events::SpanishInquisition.new
    expect{ order.apply(spanish_inquisition) }.to_not raise_error
  end

  it "should receive a method call based on a custom strategy" do
    order = OrderWithCustomStrategy.new
    order_created = Orders::Events::OrderCreated.new

    order.apply(order_created)
    expect(order.status).to eq :created
  end

  it "should return applied events" do
    order = Order.new
    created = Orders::Events::OrderCreated.new
    expired = Orders::Events::OrderExpired.new

    applied = order.apply(created, expired)
    expect(applied).to eq([created, expired])
  end

  it "should return only applied events" do
    order = Order.new
    created = Orders::Events::OrderCreated.new
    order.apply(created)

    expired = Orders::Events::OrderExpired.new
    applied = order.apply(expired)
    expect(applied).to eq([expired])
  end

  it "#unpublished_events method is public" do
    order = Order.new
    expect(order.unpublished_events.to_a).to eq([])

    created = Orders::Events::OrderCreated.new
    order.apply(created)
    expect(order.unpublished_events.to_a).to eq([created])

    expired = Orders::Events::OrderExpired.new
    order.apply(expired)
    expect(order.unpublished_events.to_a).to eq([created, expired])
  end

  it "#unpublished_events method does not allow modifying internal state directly" do
    order = Order.new
    expect(order.unpublished_events.respond_to?(:<<)).to eq(false)
    expect(order.unpublished_events.respond_to?(:clear)).to eq(false)
    expect(order.unpublished_events.respond_to?(:push)).to eq(false)
    expect(order.unpublished_events.respond_to?(:shift)).to eq(false)
    expect(order.unpublished_events.respond_to?(:pop)).to eq(false)
    expect(order.unpublished_events.respond_to?(:unshift)).to eq(false)
  end

  it "loads events from given stream" do
    event_store.publish(Orders::Events::OrderCreated.new, stream_name: "Order$1")
    event_store.publish(Orders::Events::OrderExpired.new, stream_name: "Order$2")

    order = Order.new.load("Order$1", event_store: event_store)
    expect(order.status).to eq :created
  end

  describe ".on" do
    it "generates private apply handler method" do
      order_with_ons = Class.new do
        include AggregateRoot

        on Orders::Events::OrderCreated do |_ev|
          @status = :created
        end

        on Orders::Events::OrderExpired do |_ev|
          @status = :expired
        end

        attr_accessor :status
      end

      inherited_order_with_ons = Class.new(order_with_ons) do
        on Orders::Events::OrderCreated do |_ev|
          @status = :created_inherited
        end
      end

      order = order_with_ons.new
      order.apply(Orders::Events::OrderCreated.new)
      expect(order.status).to eq(:created)
      order.apply(Orders::Events::OrderExpired.new)
      expect(order.status).to eq(:expired)

      expect(order.private_methods).to include(:"on_Orders::Events::OrderCreated")
      expect(order.private_methods).to include(:"on_Orders::Events::OrderExpired")

      order = inherited_order_with_ons.new
      order.apply(Orders::Events::OrderCreated.new)
      expect(order.status).to eq(:created_inherited)
      order.apply(Orders::Events::OrderExpired.new)
      expect(order.status).to eq(:expired)
    end

    it "handles super() with inheritance" do
      order_with_ons = Class.new do
        include AggregateRoot

        on Orders::Events::OrderCreated do |_ev|
          @status ||= []
          @status << :base_created
        end

        on Orders::Events::OrderExpired do |_ev|
          @status ||= []
          @status << :base_expired
        end

        attr_accessor :status
      end

      inherited_order_with_ons = Class.new(order_with_ons) do
        on Orders::Events::OrderCreated do |ev|
          super(ev)
          @status << :inherited_created
        end

        on Orders::Events::OrderExpired do |ev|
          @status.clear
          super(ev)
          @status << :inherited_expired
        end
      end

      order = inherited_order_with_ons.new
      order.apply(Orders::Events::OrderCreated.new)
      expect(order.status).to eq([:base_created, :inherited_created])
      order.apply(Orders::Events::OrderExpired.new)
      expect(order.status).to eq([:base_expired, :inherited_expired])
    end

    it "does not support anonymous events" do
      expect do
        Class.new do
          include AggregateRoot

          on(Class.new) do |_ev|
          end
        end
      end.to raise_error(ArgumentError, "Anonymous class is missing name")
    end
  end

  describe '.include' do
    it 'extend class with AggregateRoot::ClassMethods' do
      expect(Order).to receive(:extend).with(AggregateRoot::ClassMethods)
      Order.include(AggregateRoot)
    end
  end
end
