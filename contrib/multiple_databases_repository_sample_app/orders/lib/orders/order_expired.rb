module Orders
  class OrderExpired < Event
    attribute :order_id, Types::UUID
  end
end
