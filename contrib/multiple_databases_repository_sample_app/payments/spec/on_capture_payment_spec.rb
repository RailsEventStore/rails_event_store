require_relative 'spec_helper'

module Payments
  RSpec.describe OnCapturePayment do
    it 'capture payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{transaction_id}"

      Payments.arrange(stream, [PaymentAuthorized.new(data: {transaction_id: transaction_id, order_id: order_id, amount: 20.to_d})])
      Payments.act(CapturePayment.new(transaction_id: transaction_id))

      expect(Payments.event_store).to have_published(
        an_event(PaymentCaptured)
          .with_data(transaction_id: transaction_id)
      )
    end
  end
end
