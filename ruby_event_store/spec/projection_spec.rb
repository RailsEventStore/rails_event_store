require 'spec_helper'

module RubyEventStore
  AccountBalanceProjection = {
    :init          => -> { { total: 0 } },
    MoneyDeposited => ->(state, event) { state[:total] += event.amount },
    MoneyWithdrawn => ->(state, event) { state[:total] -= event.amount }
  }

  class OrderProjection
    Order    = Struct.new(:id, :items, :number)
    LineItem = Struct.new(:product_id, :quantity)

    def initial_state
      Order.new.tap { |order| order.items = [] }
    end

    def handled_events
      [OrderCreated, ProductAdded]
    end

    def transition(state, event)
      method_name = event.class.name.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').downcase
      send(method_name, state, event)
    end

    private
    def order_created(state, event)
      state.id = event.order_id
      state.number = event.order_number
    end

    def product_added(state, event)
      state.items << LineItem.new(event.product_id, event.quantity)
    end
  end

  describe Facade do
    let(:facade) { RubyEventStore::Facade.new(InMemoryRepository.new) }

    specify "projection as a hash" do
      stream_name = "Customer$123"
      facade.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      facade.publish_event(MoneyDeposited.new(amount: 20), stream_name)
      facade.publish_event(MoneyWithdrawn.new(amount: 5),  stream_name)
      account_balance = facade.run_projection(AccountBalanceProjection, stream_name)
      expect(account_balance).to eq(total: 25)
    end

    specify "projection as an object" do
      order_id = SecureRandom.uuid
      order_number = "2016/05/26/123"
      product_id = SecureRandom.uuid
      quantity = 3
      stream_name = "Order$#{order_id}"
      facade.publish_event(OrderCreated.new(order_id: order_id, order_number: order_number), stream_name)
      facade.publish_event(ProductAdded.new(order_id: order_id, product_id: product_id, quantity: quantity), stream_name)

      order = facade.run_projection(OrderProjection.new, stream_name)
      expect(order.id).to eq(order_id)
      expect(order.number).to eq(order_number)
      expect(order.items.size).to eq(1)
      order.items[0].tap do |item|
        expect(item.product_id).to eq(product_id)
        expect(item.quantity).to eq(quantity)
      end
    end

    specify "skip unhandled events" do
      stream_name = "Customer$123"
      facade.publish_event(OrderCreated.new(order_id: SecureRandom.uuid), stream_name)
      facade.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      account_balance = facade.run_projection(AccountBalanceProjection, stream_name)
      expect(account_balance).to eq(total: 10)
    end
  end
end
