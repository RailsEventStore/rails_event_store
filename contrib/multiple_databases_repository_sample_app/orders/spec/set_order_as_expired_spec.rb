require_relative 'spec_helper'

module Orders
  RSpec.describe SetOrderAsExpired do
    let(:aggregate_id) { SecureRandom.uuid }
    let(:stream) { "Orders::Order$#{aggregate_id}" }
    let(:customer_id) { 997 }
    let(:product_id) { 123 }
    let(:order_number) { "2019/01/60" }

    it 'draft order will expire' do
      Orders.arrange(stream, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id})])

      Orders.act(SetOrderAsExpired.new(order_id: aggregate_id))

      expect(Orders.event_store).to have_published(
        an_event(OrderExpired)
          .with_data(
            order_id: aggregate_id,
          )
        )
    end

    it 'submitted order will expire' do
      Orders.arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: '2018/12/1', customer_id: customer_id}),
      ])

      Orders.act(SetOrderAsExpired.new(order_id: aggregate_id))

      expect(Orders.event_store).to have_published(
        an_event(OrderExpired)
          .with_data(
            order_id: aggregate_id,
          )
        )
    end

    it 'paid order cannot expire' do
      Orders.arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id}),
        OrderSubmitted.new(data: {order_id: aggregate_id, order_number: '2018/12/1', customer_id: customer_id}),
        OrderPaid.new(data: {order_id: aggregate_id, transaction_id: SecureRandom.hex(16)}),
      ])

      expect do
        Orders.act(SetOrderAsExpired.new(order_id: aggregate_id))
      end.to raise_error(Order::AlreadyPaid)
    end
  end
end
