require_relative 'spec_helper'

module Orders
  RSpec.describe AddItemToBasket do
    let(:aggregate_id) { SecureRandom.uuid }
    let(:stream) { "Orders::Order$#{aggregate_id}" }
    let(:customer_id) { 997 }
    let(:address_id) { 998 }
    let(:payment_method_id) { 999 }
    let(:product_id) { 123 }
    let(:order_number) { "2019/01/60" }

    it 'item is added to draft order' do
      Orders.act(AddItemToBasket.new(order_id: aggregate_id, product_id: product_id))
      expect(Orders.event_store).to have_published(
        an_event(ItemAddedToBasket)
          .with_data(order_id: aggregate_id, product_id: product_id)
      )
    end

    it 'no add allowed to submitted order' do
      Orders.arrange(stream, [
        ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id}),
        OrderSubmitted.new(data: {
          order_id: aggregate_id,
          order_number: order_number,
          customer_id: customer_id,
          delivery_address_id: address_id,
          payment_method_id: payment_method_id,
        })
      ])

      expect do
        Orders.act(AddItemToBasket.new(order_id: aggregate_id, product_id: product_id))
      end.to raise_error(Order::AlreadySubmitted)
    end
  end
end
