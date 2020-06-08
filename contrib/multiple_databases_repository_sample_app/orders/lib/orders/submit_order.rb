module Orders
  class SubmitOrder < Command
    attribute :order_id, Types::UUID
    attribute :customer_id, Types::Coercible::Integer
  end
end
