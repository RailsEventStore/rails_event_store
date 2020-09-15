module Payments
  class CapturePayment < Command
    attribute :transaction_id, Types::Coercible::String
  end
end
