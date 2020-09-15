module Payments
  class PaymentReleased < Event
    attribute :transaction_id, Types::TransactionId
  end
end
