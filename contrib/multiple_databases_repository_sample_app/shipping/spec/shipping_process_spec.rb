require 'spec_helper'

module Shipping
  RSpec.describe ShippingProcess do
    let(:order_id) { SecureRandom.uuid }
    let(:customer_id) { 123 }
    let(:address_id) { 999 }

    it 'works' do
      Shipping.public_event_store.publish(OrderPlaced.new(
        order_id: order_id,
        customer_id: customer_id,
        delivery_address_id: address_id,
      ))
      Shipping.public_event_store.publish(OrderPaid.new(
        order_id: order_id,
      ))

      expect(Shipping.event_store).to have_published(
        an_event(Shipping::PackageShipped).with_data(
          order_id: order_id,
          customer_id: customer_id,
          delivery_address_id: address_id,
          tracking_number: kind_of(String),
          estimated_delivery_date: 2.days.from_now.to_date,
        )
      )

      expect(Shipping.public_event_store).to have_published(
        an_event(Shipping::OrderSent).with_data(
          order_id: order_id,
          tracking_number: kind_of(String),
          estimated_delivery_date: 2.days.from_now.to_date,
        )
      )
    end
  end
end
