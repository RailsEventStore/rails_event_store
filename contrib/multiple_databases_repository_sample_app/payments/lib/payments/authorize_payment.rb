module Payments
  class AuthorizePayment < Command
    attribute :transaction_id, Types::Coercible::String
    attribute :order_id, Types::UUID
    attribute :amount, Types::Decimal
  end
end
