module Payments
  class PaymentReleased < Event
    attribute :order_id,       Types::UUID
    attribute :transaction_id, Types::TransactionId
  end
end
