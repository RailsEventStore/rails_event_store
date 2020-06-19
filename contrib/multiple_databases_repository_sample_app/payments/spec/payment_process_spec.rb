require 'spec_helper'

module Payments
  RSpec.describe PaymentProcess do
    let(:transaction_id) { SecureRandom.hex(16) }
    let(:order_id) { SecureRandom.uuid }

    it 'complete captured payment' do
      Payments.act(AuthorizePayment.new(transaction_id: transaction_id, order_id: order_id, amount: 20.to_d))
      Payments.act(CapturePayment.new(transaction_id: transaction_id, order_id: order_id))

      expect(Payments.public_event_store).to have_published(
        an_event(Payments::PaymentCompleted).with_data(
          transaction_id: transaction_id,
          order_id: order_id,
        )
      )
    end

    it 'release expired payment' do
      Payments.act(AuthorizePayment.new(transaction_id: transaction_id, order_id: order_id, amount: 20.to_d))
      Payments.act(SetPaymentAsExpired.new(transaction_id: transaction_id))

      expect(Payments.public_event_store).not_to have_published(
        an_event(Payments::PaymentCompleted)
      )

      expect(Payments.event_store).to have_published(
        an_event(Payments::PaymentReleased).with_data(
          transaction_id: transaction_id,
        )
      )
    end
  end
end
