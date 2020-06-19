module Orders
  class PlaceOrder < Command
    attribute :order_id, Types::UUID
    attribute :customer_id, Types::Coercible::Integer
    attribute :delivery_address_id, Types::Coercible::Integer
    attribute :payment_method_id, Types::Coercible::Integer
    attribute :amount, Types::Decimal
  end
end
