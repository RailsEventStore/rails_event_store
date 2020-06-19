require 'spec_helper'

module Payments
  RSpec.describe InitiatePayment do
    let(:order_id) { SecureRandom.uuid }

    it 'works' do
      Payments.public_event_store.publish(
        PaymentInitiated.new(
          order_id: order_id,
          amount: 20.to_d,
        )
      )

      expect(Payments.event_store).to have_published(
        an_event(PaymentAuthorized).with_data(
          transaction_id: kind_of(String),
          order_id: order_id,
          amount: 20.to_d,
        )
      )
    end
  end
end
