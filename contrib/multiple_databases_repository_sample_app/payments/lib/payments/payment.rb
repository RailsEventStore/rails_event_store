module Payments
  class Payment
    include AggregateRoot

    AlreadyAuthorized = Class.new(StandardError)
    NotAuthorized = Class.new(StandardError)
    AlreadyCaptured = Class.new(StandardError)
    AlreadyReleased = Class.new(StandardError)

    def initialize
      @state = nil
    end

    def authorize(transaction_id, order_id, amount)
      raise AlreadyAuthorized unless initiated?
      apply(PaymentAuthorized.new(data: {
        transaction_id: transaction_id,
        order_id: order_id,
        amount: amount
      }))
    end

    def expire
      raise NotAuthorized unless authorized?
      raise AlreadyCaptured if captured?
      raise AlreadyReleased if released?
      apply(PaymentExpired.new(data: {
        transaction_id: @transaction_id,
      }))
    end

    def capture
      raise NotAuthorized unless authorized?
      raise AlreadyCaptured if captured?
      apply(PaymentCaptured.new(data: {
        transaction_id: @transaction_id,
      }))
    end

    def release
      raise NotAuthorized unless authorized?
      raise AlreadyCaptured if captured?
      raise AlreadyReleased if released?
      apply(PaymentReleased.new(data: {
        transaction_id: @transaction_id,
      }))
    end

    private

    on PaymentAuthorized do |event|
      @state = :authorized
      @transaction_id = event.transaction_id
      @order_id = event.order_id
      @amount = event.amount
    end

    on PaymentExpired do |event|
      @state = :expired
    end

    on PaymentCaptured do |event|
      @state = :captured
    end

    on PaymentReleased do |event|
      @state = :released
    end

    def initiated?
      @state == nil
    end

    def authorized?
      @state != nil
    end

    def expired?
      @state == :expired
    end

    def captured?
      @state == :captured
    end

    def released?
      @state == :released
    end
  end
end

