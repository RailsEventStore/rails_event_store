module Orders
  class SetOrderAsExpired < Command
    attribute :order_id, Types::UUID
  end
end
