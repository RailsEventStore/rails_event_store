require_relative 'spec_helper'

module Orders
  RSpec.describe MarkOrderAsPaid do
    let(:aggregate_id) { SecureRandom.uuid }
    let(:stream) { "Orders::Order$#{aggregate_id}" }
    let(:customer_id) { 997 }
    let(:product_id) { 123 }
    let(:order_number) { "2019/01/60" }

    it 'draft order could not be marked as paid' do
      Orders.arrange(stream, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id})])

      expect do
        Orders.act(MarkOrderAsPaid.new(order_id: aggregate_id, transaction_id: SecureRandom.hex(16)))
      end.to raise_error(Order::NotSubmitted)
    end

    it 'submitted order will be marked as paid' do
      Orders.arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: '2018/12/1', customer_id: customer_id}),
      ])

      transaction_id = SecureRandom.hex(16)
      Orders.act(MarkOrderAsPaid.new(order_id: aggregate_id, transaction_id: transaction_id))

      expect(Orders.event_store).to have_published(
        an_event(OrderPaid)
          .with_data(order_id: aggregate_id, transaction_id: transaction_id)
      )
    end

    it 'expired order cannot be marked as paid' do
      Orders.arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: '2018/12/1', customer_id: customer_id}),
        OrderExpired.new(data: {order_id: aggregate_id}),
      ])

      expect do
        Orders.act(MarkOrderAsPaid.new(order_id: aggregate_id, transaction_id: SecureRandom.hex(16)))
      end.to raise_error(Order::OrderHasExpired)
    end
  end
end
