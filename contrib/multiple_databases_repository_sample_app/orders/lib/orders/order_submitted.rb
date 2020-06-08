module Orders
  class OrderSubmitted < Event
    attribute :order_id,     Types::UUID
    attribute :order_number, Types::OrderNumber
    attribute :customer_id,  Types::ID
  end
end
