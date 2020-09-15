module Payments
  class PaymentAuthorized < Event
    attribute :order_id,       Types::UUID
    attribute :transaction_id, Types::TransactionId
    attribute :amount,         Types::Coercible::Decimal
  end
end
