# frozen_string_literal: true

require "spec_helper"

::RSpec.describe AggregateRoot do
  
  let(:uuid) { SecureRandom.uuid }
  let(:order_klass) do
    Class.new do
      include AggregateRoot

      def initialize(uuid)
        @status = :draft
        @uuid = uuid
      end

      def create
        apply Orders::Events::OrderCreated.new
      end

      def expire
        apply Orders::Events::OrderExpired.new
      end

      attr_accessor :status

      private

      def apply_order_created(_event)
        @status = :created
      end

      def apply_order_expired(_event)
        @status = :expired
      end
    end
  end

  it "has ability to apply event on itself" do
    order = order_klass.new(uuid)
    order_created = Orders::Events::OrderCreated.new

    expect(order).to receive(:"apply_order_created").with(order_created).and_call_original
    order.apply(order_created)
    expect(order.status).to eq :created
    expect(order.unpublished_events.to_a).to eq([order_created])
  end

  it "brand new aggregate does not have any unpublished events" do
    order = order_klass.new(uuid)
    expect(order.unpublished_events.to_a).to be_empty
  end

  it "receives a method call based on a default apply strategy" do
    order = order_klass.new(uuid)
    order_created = Orders::Events::OrderCreated.new

    order.apply(order_created)
    expect(order.status).to eq :created
  end

  it "raises error for missing apply method based on a default apply strategy" do
    order = order_klass.new(uuid)
    spanish_inquisition = Orders::Events::SpanishInquisition.new
    expect { order.apply(spanish_inquisition) }.to raise_error(
      AggregateRoot::MissingHandler,
      "Missing handler method apply_spanish_inquisition on aggregate #{order_klass}"
    )
  end

  it "ignores missing apply method based on a default non-strict apply strategy" do
    klass =
      Class.new { include AggregateRoot.with_strategy(-> { AggregateRoot::DefaultApplyStrategy.new(strict: false) }) }
    order = klass.new
    spanish_inquisition = Orders::Events::SpanishInquisition.new
    expect { order.apply(spanish_inquisition) }.not_to raise_error
  end

  it "receives a method call based on a custom strategy" do
    strategy = -> do
      ->(aggregate, event) do
        {
          "Orders::Events::OrderCreated" => aggregate.method(:custom_created),
          "Orders::Events::OrderExpired" => aggregate.method(:custom_expired)
        }.fetch(event.event_type, ->(ev) {  }).call(event)
      end
    end
    klass =
      Class.new do
        include AggregateRoot.with_strategy(strategy)

        def initialize
          @status = :draft
        end

        attr_accessor :status

        private

        def custom_created(_event)
          @status = :created
        end

        def custom_expired(_event)
          @status = :expired
        end
      end
    order = klass.new
    order_created = Orders::Events::OrderCreated.new

    order.apply(order_created)
    expect(order.status).to eq :created
  end

  it "ruby 2.7 compatibility" do
    klass = Class.new { include AggregateRoot.with_default_apply_strategy }

    # This is just a way to ensure that the AggregateMethods was included on
    # the klass directly, not that it was an include to the anonymous module.
    # This test can be removed when ruby 2.7 will be no longer supported.
    expect(klass.included_modules[0]).to eq(AggregateRoot::AggregateMethods)
  end

  it "returns applied events" do
    order = order_klass.new(uuid)
    created = Orders::Events::OrderCreated.new
    expired = Orders::Events::OrderExpired.new

    applied = order.apply(created, expired)
    expect(applied).to eq([created, expired])
  end

  it "returns only applied events" do
    order = order_klass.new(uuid)
    created = Orders::Events::OrderCreated.new
    order.apply(created)

    expired = Orders::Events::OrderExpired.new
    applied = order.apply(expired)
    expect(applied).to eq([expired])
  end

  it "#unpublished_events method is public" do
    order = order_klass.new(uuid)
    expect(order.unpublished_events.to_a).to eq([])

    created = Orders::Events::OrderCreated.new
    order.apply(created)
    expect(order.unpublished_events.to_a).to eq([created])

    expired = Orders::Events::OrderExpired.new
    order.apply(expired)
    expect(order.unpublished_events.to_a).to eq([created, expired])
  end

  it "#unpublished_events method does not allow modifying internal state directly" do
    order = order_klass.new(uuid)
    expect(order.unpublished_events.respond_to?(:<<)).to be(false)
    expect(order.unpublished_events.respond_to?(:clear)).to be(false)
    expect(order.unpublished_events.respond_to?(:push)).to be(false)
    expect(order.unpublished_events.respond_to?(:shift)).to be(false)
    expect(order.unpublished_events.respond_to?(:pop)).to be(false)
    expect(order.unpublished_events.respond_to?(:unshift)).to be(false)
  end

  describe ".on" do
    it "generates private apply handler method" do
      order_with_ons =
        Class.new do
          include AggregateRoot

          on Orders::Events::OrderCreated do |_ev|
            @status = :created
          end

          on "Orders::Events::OrderExpired" do |_ev|
            @status = :expired
          end

          attr_accessor :status
        end

      inherited_order_with_ons =
        Class.new(order_with_ons) do
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
      order_with_ons =
        Class.new do
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

      inherited_order_with_ons =
        Class.new(order_with_ons) do
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
      expect(order.status).to eq(%i[base_created inherited_created])
      order.apply(Orders::Events::OrderExpired.new)
      expect(order.status).to eq(%i[base_expired inherited_expired])
    end

    it "does not support anonymous events" do
      expect do
        Class.new do
          include AggregateRoot

          on(Class.new) { |_ev| }
        end
      end.to raise_error(ArgumentError, "Anonymous class is missing name")
    end
  end

  describe "#initialize" do
    it "allows default initializer" do
      aggregate_klass =
        Class.new do
          include AggregateRoot
          def initialize
            @state = :draft
          end
          attr_reader :state
        end

      aggregate = aggregate_klass.new
      expect(aggregate.state).to eq(:draft)
    end

    it "allows initializer with arguments" do
      aggregate_klass =
        Class.new do
          include AggregateRoot
          def initialize(a, b)
            @state = a + b
          end
          attr_reader :state
        end

      aggregate = aggregate_klass.new(2, 3)
      expect(aggregate.state).to eq(5)
    end

    it "allows initializer with keyword arguments" do
      aggregate_klass =
        Class.new do
          include AggregateRoot
          def initialize(a:, b:)
            @state = a + b
          end
          attr_reader :state
        end

      aggregate = aggregate_klass.new(a: 2, b: 3)
      expect(aggregate.state).to eq(5)
    end

    it "allows initializer with variable arguments" do
      aggregate_klass =
        Class.new do
          include AggregateRoot
          def initialize(*args)
            @state = args.reduce(:+)
          end
          attr_reader :state
        end

      aggregate = aggregate_klass.new(1, 2, 3)
      expect(aggregate.state).to eq(6)
    end

    it "allows initializer with variable keyword arguments" do
      aggregate_klass =
        Class.new do
          include AggregateRoot
          def initialize(**args)
            @state = args.values.reduce(:+)
          end
          attr_reader :state
        end

      aggregate = aggregate_klass.new(a: 1, b: 2, c: 3)
      expect(aggregate.state).to eq(6)
    end

    it "allows initializer with mixed arguments" do
      aggregate_klass =
        Class.new do
          include AggregateRoot
          def initialize(a, *args, b:, **kwargs)
            @state = a + b + args.reduce(:+) + kwargs.values.reduce(:+)
          end
          attr_reader :state
        end

      aggregate = aggregate_klass.new(1, 2, 3, b: 4, c: 5, d: 6)
      expect(aggregate.state).to eq(21)
    end

    it "allows initializer with block" do
      aggregate_klass =
        Class.new do
          include AggregateRoot
          def initialize(a, *args, b:, **kwargs, &block)
            @state = block.call(a + b + args.reduce(:+) + kwargs.values.reduce(:+))
          end
          attr_reader :state
        end

      aggregate = aggregate_klass.new(1, 2, 3, b: 4, c: 5, d: 6) { |val| val * 2 }
      expect(aggregate.state).to eq(42)
    end
  end
end
