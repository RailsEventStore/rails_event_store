require_relative 'spec_helper'

module Payments
  RSpec.describe OnAuthorizePayment do
    it 'authorize payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid

      act(AuthorizePayment.new(transaction_id: transaction_id, order_id: order_id))

      expect(Payments.event_store).to have_published(
        an_event(PaymentAuthorized)
          .with_data(transaction_id: transaction_id, order_id: order_id)
      )
    end
  end
end

