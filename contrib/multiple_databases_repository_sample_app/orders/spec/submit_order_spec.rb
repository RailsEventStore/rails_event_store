require_relative 'spec_helper'

module Orders
  RSpec.describe SubmitOrder do
    let(:aggregate_id) { SecureRandom.uuid }
    let(:stream) { "Orders::Order$#{aggregate_id}" }
    let(:customer_id) { 997 }
    let(:address_id) { 998 }
    let(:payment_method_id) { 999 }
    let(:product_id) { 123 }
    let(:order_number) { "2019/01/60" }

    it 'order is submitted' do
      Orders.arrange(stream, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product_id})])
      Orders.act(SubmitOrder.new(
        order_id: aggregate_id,
        customer_id: customer_id,
        delivery_address_id: address_id,
        payment_method_id: payment_method_id,
      ))

      expect(Orders.event_store).to have_published(
        an_event(OrderSubmitted)
          .with_data(
            order_id: aggregate_id,
            order_number: order_number,
            customer_id: customer_id,
            delivery_address_id: address_id,
            payment_method_id: payment_method_id,
          )
        )
    end

    it 'could not create order where customer is not given' do
      expect do
        Orders.act(SubmitOrder.new(
          order_id: aggregate_id,
          customer_id: nil,
          delivery_addredd_id: nil,
          payment_method_id: nil
        ))
      end.to raise_error(Command::Invalid)
    end

    it 'already created order could not be created again' do
      another_customer_id = 998
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
        Orders.act(SubmitOrder.new(
          order_id: aggregate_id,
          customer_id: another_customer_id,
          delivery_address_id: address_id,
          payment_method_id: payment_method_id,
        ))
      end.to raise_error(Order::AlreadySubmitted)
    end
  end
end
