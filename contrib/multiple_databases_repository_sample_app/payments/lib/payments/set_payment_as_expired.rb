module Payments
  class SetPaymentAsExpired < Command
    attribute :transaction_id, Types::Coercible::String
  end
end
