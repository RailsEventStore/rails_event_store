module Payments
  class Payment
    include AggregateRoot

    AlreadyAuthorized = Class.new(StandardError)
    NotAuthorized = Class.new(StandardError)
    AlreadyCaptured = Class.new(StandardError)
    AlreadyReleased = Class.new(StandardError)

    def authorize(transaction_id, order_id, amount)
      raise AlreadyAuthorized if authorized?
      apply(PaymentAuthorized.new(data: {
        transaction_id: transaction_id,
        order_id: order_id,
        amount: amount
      }))
    end

    def capture
      raise AlreadyCaptured if captured?
      raise NotAuthorized unless authorized?
      apply(PaymentCaptured.new(data: {
        transaction_id: @transaction_id,
        order_id: @order_id
      }))
    end

    def release
      raise AlreadyReleased if released?
      raise AlreadyCaptured if captured?
      raise NotAuthorized unless authorized?
      apply(PaymentReleased.new(data: {
        transaction_id: @transaction_id,
        order_id: @order_id
      }))
    end

    private

    on PaymentAuthorized do |event|
      @state = :authorized
      @transaction_id = event.transaction_id
      @order_id = event.order_id
      @amount = event.amount
    end

    on PaymentCaptured do |event|
      @state = :captured
    end

    on PaymentReleased do |event|
      @state = :released
    end

    def authorized?
      @state == :authorized
    end

    def captured?
      @state == :captured
    end

    def released?
      @state == :released
    end
  end
end

