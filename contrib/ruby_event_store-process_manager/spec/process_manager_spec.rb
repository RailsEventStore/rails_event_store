# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyEventStore::ProcessManager do
  let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
  let(:command_bus) { FakeCommandBus.new }

  class FakeCommandBus
    attr_reader :commands

    def initialize
      @commands = []
    end

    def call(command)
      @commands << command
    end
  end

  OrderPaid = Class.new(RubyEventStore::Event)
  OrderAddressSet = Class.new(RubyEventStore::Event)
  DeliverOrder = Data.define(:order_id)

  OrderDeliveryState = Data.define(:paid, :address_set) do
    def initialize(paid: false, address_set: false)
      super
    end

    def ready_to_deliver?
      paid && address_set
    end
  end

  class OrderDeliveryProcess
    include RubyEventStore::ProcessManager.with_state { OrderDeliveryState }

    subscribes_to OrderPaid, OrderAddressSet

    private

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def apply(event)
      case event
      when OrderPaid
        state.with(paid: true)
      when OrderAddressSet
        state.with(address_set: true)
      else
        state
      end
    end

    def act
      command_bus.call(DeliverOrder.new(order_id: id)) if state.ready_to_deliver?
    end
  end

  specify "issues command when all conditions are met" do
    process = OrderDeliveryProcess.new(event_store, command_bus)
    order_id = "order-123"

    paid_event = OrderPaid.new(data: { order_id: order_id })
    event_store.append(paid_event)
    process.call(paid_event)

    expect(command_bus.commands).to be_empty

    address_event = OrderAddressSet.new(data: { order_id: order_id })
    event_store.append(address_event)
    process.call(address_event)

    expect(command_bus.commands).to eq([DeliverOrder.new(order_id: order_id)])
  end

  specify "works regardless of event order" do
    process = OrderDeliveryProcess.new(event_store, command_bus)
    order_id = "order-456"

    address_event = OrderAddressSet.new(data: { order_id: order_id })
    event_store.append(address_event)
    process.call(address_event)

    expect(command_bus.commands).to be_empty

    paid_event = OrderPaid.new(data: { order_id: order_id })
    event_store.append(paid_event)
    process.call(paid_event)

    expect(command_bus.commands).to eq([DeliverOrder.new(order_id: order_id)])
  end

  specify "subscribes_to registers event classes" do
    expect(OrderDeliveryProcess.subscribed_events).to eq([OrderPaid, OrderAddressSet])
  end
end
