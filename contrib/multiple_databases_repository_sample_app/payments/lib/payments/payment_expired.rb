module Payments
  class PaymentExpired < Event
    attribute :transaction_id, Types::TransactionId
  end
end
