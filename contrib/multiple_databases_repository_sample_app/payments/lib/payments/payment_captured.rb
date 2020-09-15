module Payments
  class PaymentCaptured < Event
    attribute :transaction_id, Types::TransactionId
  end
end
