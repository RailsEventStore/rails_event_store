require_relative 'spec_helper'

module Payments
  RSpec.describe Payment do
    it 'authorize' do
      payment = Payment.new
      expect do
        payment.authorize(transaction_id, order_id, 20.to_d)
      end.to apply(
        an_event(PaymentAuthorized)
          .with_data(
            transaction_id: transaction_id,
            order_id: order_id,
            amount: 20.to_d,
          )
      ).in(payment)
    end

    it 'should not allow for double authorization' do
      expect do
        authorized_payment.authorize(transaction_id, order_id, 20.to_d)
      end.to raise_error(Payment::AlreadyAuthorized)
    end

    it 'should capture authorized payment' do
      payment = authorized_payment

      expect do
        payment.capture
      end.to apply(
        an_event(PaymentCaptured)
          .with_data(transaction_id: transaction_id)
      ).in(payment)
    end

    it 'must not capture not authorized payment' do
      expect do
        Payment.new.capture
      end.to raise_error(Payment::NotAuthorized)
    end

    it 'should not allow for double capture' do
      expect do
        captured_payment.capture
      end.to raise_error(Payment::AlreadyCaptured)
    end

    it 'authorization could be released' do
      payment = authorized_payment

      expect do
        payment.release
      end.to apply(
        an_event(PaymentReleased)
          .with_data(transaction_id: transaction_id)
      ).in(payment)
    end

    it 'must not release not captured payment' do
      expect do
        captured_payment.release
      end.to raise_error(Payment::AlreadyCaptured)
    end

    it 'must not release not authorized payment' do
      expect do
        Payment.new.release
      end.to raise_error(Payment::NotAuthorized)
    end

    it 'should not allow for double release' do
      expect do
        released_payment.release
      end.to raise_error(Payment::AlreadyReleased)
    end

    let(:transaction_id) { SecureRandom.hex(16) }
    let(:order_id) { SecureRandom.uuid }

    def authorized_payment
      Payment.new.tap do |payment|
        payment.apply(
          PaymentAuthorized.new(data: {
            transaction_id: transaction_id,
            order_id: order_id,
            amount: 20.to_d,
          })
        )
      end
    end

    def captured_payment
      authorized_payment.tap do |payment|
        payment.apply(
          PaymentCaptured.new(data: {
            transaction_id: transaction_id,
          })
        )
      end
    end

    def released_payment
      captured_payment.tap do |payment|
        payment.apply(
          PaymentReleased.new(data: {
            transaction_id: transaction_id,
          })
        )
      end
    end
  end
end
