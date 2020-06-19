require_relative 'spec_helper'

module Payments
  RSpec.describe OnAuthorizePayment do
    it 'authorize payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid

      Payments.act(AuthorizePayment.new(transaction_id: transaction_id, order_id: order_id, amount: 20.to_d))

      expect(Payments.event_store).to have_published(
        an_event(PaymentAuthorized)
          .with_data(
            transaction_id: transaction_id,
            order_id: order_id,
            amount: 20.to_d
          )
      )
    end
  end
end

