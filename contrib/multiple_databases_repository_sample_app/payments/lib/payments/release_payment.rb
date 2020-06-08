module Payments
  class ReleasePayment < Command
    attribute :transaction_id, Types::Coercible::String
  end
end
