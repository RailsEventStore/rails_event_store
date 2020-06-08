module Orders
  class MarkOrderAsPaid < Command
    attribute :order_id, Types::UUID
    attribute :transaction_id, Types::Coercible::String
  end
end
