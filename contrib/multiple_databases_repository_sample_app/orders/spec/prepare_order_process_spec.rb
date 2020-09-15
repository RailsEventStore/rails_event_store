require 'spec_helper'

module Orders
  RSpec.describe PrepareOrderProcess do
    let(:order_id) { SecureRandom.uuid }
    let(:stream) { "Orders::Order$#{order_id}" }
    let(:customer_id) { 997 }
    let(:address_id) { 998 }
    let(:payment_method_id) { 999 }
    let(:product_id) { 123 }
    let(:order_number) { "2019/01/60" }

    it 'works' do
      Orders.act(AddItemToBasket.new(order_id: order_id, product_id: product_id))
      Orders.act(AddItemToBasket.new(order_id: order_id, product_id: product_id))
      Orders.act(SubmitOrder.new(
        order_id: order_id,
        customer_id: customer_id,
        delivery_address_id: address_id,
        payment_method_id: payment_method_id,
      ))

      expect(Orders.public_event_store).to have_published(
        an_event(Orders::OrderPlaced).with_data(
          order_id: order_id,
          customer_id: customer_id,
          delivery_address_id: address_id,
          payment_method_id: payment_method_id,
          amount: 20.to_d,
        )
      )
    end
  end
end
