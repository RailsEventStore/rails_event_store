module Orders
  class OrderSubmitted < Event
    attribute :order_id, Types::UUID
    attribute :order_number, Types::OrderNumber
    attribute :customer_id, Types::ID
    attribute :delivery_address_id, Types::ID
    attribute :payment_method_id, Types::ID
  end
end
