module Orders
  class OrderPaid < Event
    attribute :order_id,       Types::UUID
    attribute :transaction_id, Types::TransactionId
  end
end
