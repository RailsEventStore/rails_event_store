require 'spec_helper'

RSpec.describe AggregateRoot do
  let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }

  it "should have ability to apply event on itself" do
    order = Order.new(SecureRandom.uuid)
    order_created = Orders::Events::OrderCreated.new

    expect(order).to receive(:"apply_order_created").with(order_created).and_call_original
    order.apply(order_created)
    expect(order.status).to eq :created
    expect(order.unpublished_events.to_a).to eq([order_created])
  end

  it "brand new aggregate does not have any unpublished events" do
    order = Order.new(SecureRandom.uuid)
    expect(order.unpublished_events.to_a).to be_empty
  end

  it "should have no unpublished events when loaded" do
    stream = "any-order-stream"
    order_created = Orders::Events::OrderCreated.new
    event_store.publish(order_created, stream_name: stream)

    repository = AggregateRoot::Repository.new(event_store)
    order = repository.load(Order.new(SecureRandom.uuid), stream)
    expect(order.status).to eq :created
    expect(order.unpublished_events.to_a).to be_empty
  end

  it "should publish all unpublished events on store" do
    stream = "any-order-stream"
    order_created = Orders::Events::OrderCreated.new
    order_expired = Orders::Events::OrderExpired.new

    repository = AggregateRoot::Repository.new(event_store)
    order = Order.new(SecureRandom.uuid)
    order.apply(order_created)
    order.apply(order_expired)
    expect(event_store).not_to receive(:publish).with(kind_of(Enumerator), any_args)
    expect(event_store).not_to receive(:publish).with(kind_of(Set), any_args)
    expect(event_store).to receive(:publish).with([order_created, order_expired], stream_name: stream, expected_version: -1).and_call_original
    repository.store(order, stream)
    expect(order.unpublished_events.to_a).to be_empty
  end

  it "updates aggregate stream position and uses it in subsequent publish call as expected_version" do
    stream = "any-order-stream"
    order_created = Orders::Events::OrderCreated.new

    repository = AggregateRoot::Repository.new(event_store)
    order = Order.new(SecureRandom.uuid)
    order.apply(order_created)
    expect(event_store).to receive(:publish).with([order_created], stream_name: stream, expected_version: -1).and_call_original
    repository.store(order, stream)

    order_expired = Orders::Events::OrderExpired.new
    order.apply(order_expired)
    expect(event_store).to receive(:publish).with([order_expired], stream_name: stream, expected_version: 0).and_call_original
    repository.store(order, stream)
  end

  it "should work with provided event_store" do
    with_default_event_store(double(:some_other_event_store)) do
      stream = "any-order-stream"
      repository = AggregateRoot::Repository.new(event_store)
      order = repository.load(Order.new(SecureRandom.uuid), stream)
      order_created = Orders::Events::OrderCreated.new
      order.apply(order_created)
      repository.store(order, stream)

      expect(event_store.read.stream(stream).to_a).to eq [order_created]

      restored_order = repository.load(Order.new(SecureRandom.uuid), stream)
      expect(restored_order.status).to eq :created
      order_expired = Orders::Events::OrderExpired.new
      restored_order.apply(order_expired)
      repository.store(restored_order, stream)

      expect(event_store.read.stream(stream).to_a).to eq [order_created, order_expired]

      restored_again_order = repository.load(Order.new(SecureRandom.uuid), stream)
      expect(restored_again_order.status).to eq :expired
    end
  end

  it "should use default client if event_store not provided" do
    with_default_event_store(event_store) do
      stream = "any-order-stream"
      repository = AggregateRoot::Repository.new
      order = repository.load(Order.new(SecureRandom.uuid), stream)
      order_created = Orders::Events::OrderCreated.new
      order.apply(order_created)
      repository.store(order, stream)

      expect(event_store.read.stream(stream).to_a).to eq [order_created]

      restored_order = repository.load(Order.new(SecureRandom.uuid), stream)
      expect(restored_order.status).to eq :created
      order_expired = Orders::Events::OrderExpired.new
      restored_order.apply(order_expired)
      repository.store(restored_order, stream)

      expect(event_store.read.stream(stream).to_a).to eq [order_created, order_expired]

      restored_again_order = repository.load(Order.new(SecureRandom.uuid), stream)
      expect(restored_again_order.status).to eq :expired
    end
  end

  it "if loaded from some stream should store to the same stream is no other stream specified" do
    with_default_event_store(event_store) do
      stream = "any-order-stream"
      repository = AggregateRoot::Repository.new
      order = repository.load(Order.new(SecureRandom.uuid), stream)
      order_created = Orders::Events::OrderCreated.new
      order.apply(order_created)
      repository.store(order, stream)

      expect(event_store.read.stream(stream).to_a).to eq [order_created]
    end
  end

  it "should receive a method call based on a default apply strategy" do
    order = Order.new(SecureRandom.uuid)
    order_created = Orders::Events::OrderCreated.new

    order.apply(order_created)
    expect(order.status).to eq :created
  end

  it "should raise error for missing apply method based on a default apply strategy" do
    order = Order.new(SecureRandom.uuid)
    spanish_inquisition = Orders::Events::SpanishInquisition.new
    expect { order.apply(spanish_inquisition) }.to raise_error(AggregateRoot::MissingHandler, "Missing handler method apply_spanish_inquisition on aggregate Order")
  end

  it "should ignore missing apply method based on a default non-strict apply strategy" do
    order = OrderWithNonStrictApplyStrategy.new
    spanish_inquisition = Orders::Events::SpanishInquisition.new
    expect { order.apply(spanish_inquisition) }.to_not raise_error
  end

  it "should receive a method call based on a custom strategy" do
    order = OrderWithCustomStrategy.new
    order_created = Orders::Events::OrderCreated.new

    order.apply(order_created)
    expect(order.status).to eq :created
  end

  it "should return applied events" do
    order = Order.new(SecureRandom.uuid)
    created = Orders::Events::OrderCreated.new
    expired = Orders::Events::OrderExpired.new

    applied = order.apply(created, expired)
    expect(applied).to eq([created, expired])
  end

  it "should return only applied events" do
    order = Order.new(SecureRandom.uuid)
    created = Orders::Events::OrderCreated.new
    order.apply(created)

    expired = Orders::Events::OrderExpired.new
    applied = order.apply(expired)
    expect(applied).to eq([expired])
  end

  it "#unpublished_events method is public" do
    order = Order.new(SecureRandom.uuid)
    expect(order.unpublished_events.to_a).to eq([])

    created = Orders::Events::OrderCreated.new
    order.apply(created)
    expect(order.unpublished_events.to_a).to eq([created])

    expired = Orders::Events::OrderExpired.new
    order.apply(expired)
    expect(order.unpublished_events.to_a).to eq([created, expired])
  end

  it "#unpublished_events method does not allow modifying internal state directly" do
    order = Order.new(SecureRandom.uuid)
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

    repository = AggregateRoot::Repository.new(event_store)
    order = repository.load(Order.new(SecureRandom.uuid), "Order$1")
    expect(order.status).to eq :created
  end

  describe ".on" do
    it "generates private apply handler method" do
      order_with_ons = Class.new do
        include AggregateRoot

        on Orders::Events::OrderCreated do |_ev|
          @status = :created
        end

        on 'Orders::Events::OrderExpired' do |_ev|
          @status = :expired
        end

        attr_accessor :status
      end

      inherited_order_with_ons = Class.new(order_with_ons) do
        on Orders::Events::OrderCreated do |_ev|
          @status = :created_inherited
        end

        on Orders::Events::OrderCanceled do |_ev|
          @status = :canceled_inherited
        end
      end

      order = order_with_ons.new
      order.apply(Orders::Events::OrderCreated.new)
      expect(order.status).to eq(:created)
      order.apply(Orders::Events::OrderExpired.new)
      expect(order.status).to eq(:expired)

      expect(order.private_methods).to include(:"on_Orders::Events::OrderCreated")
      expect(order.private_methods).to include(:"on_Orders::Events::OrderExpired")

      expect(order_with_ons.on_methods.keys).to include("Orders::Events::OrderCreated")
      expect(order_with_ons.on_methods.keys).to include("Orders::Events::OrderExpired")

      order = inherited_order_with_ons.new
      order.apply(Orders::Events::OrderCreated.new)
      expect(order.status).to eq(:created_inherited)
      order.apply(Orders::Events::OrderExpired.new)
      expect(order.status).to eq(:expired)
      order.apply(Orders::Events::OrderCanceled.new)
      expect(order.status).to eq(:canceled_inherited)

      expect(order.private_methods).to include(:"on_Orders::Events::OrderCreated")
      expect(order.private_methods).to include(:"on_Orders::Events::OrderExpired")
      expect(order.private_methods).to include(:"on_Orders::Events::OrderCanceled")

      expect(inherited_order_with_ons.on_methods.keys).to include("Orders::Events::OrderCreated")
      expect(inherited_order_with_ons.on_methods.keys).to include("Orders::Events::OrderExpired")
      expect(inherited_order_with_ons.on_methods.keys).to include("Orders::Events::OrderCanceled")
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

  it "uses with_aggregate to simplify aggregate usage" do
    event_store.publish(Orders::Events::OrderCreated.new, stream_name: "Order$1")
    order_expired = Orders::Events::OrderExpired.new
    expect(event_store).to receive(:publish).with([order_expired], stream_name: "Order$1", expected_version: 0).and_call_original
    repository = AggregateRoot::Repository.new(event_store)
    repository.with_aggregate(Order.new(SecureRandom.uuid), "Order$1") do |order|
      order.apply(order_expired)
    end
  end

  def with_default_event_store(store)
    previous = AggregateRoot.configuration.default_event_store
    AggregateRoot.configure do |config|
      config.default_event_store = store
    end
    yield
    AggregateRoot.configure do |config|
      config.default_event_store = previous
    end
  end
end
