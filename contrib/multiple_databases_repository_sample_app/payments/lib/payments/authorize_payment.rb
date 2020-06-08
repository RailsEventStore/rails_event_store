module Payments
  class AuthorizePayment < Command
    attribute :transaction_id, Types::Coercible::String
    attribute :order_id, Types::UUID
  end
end
