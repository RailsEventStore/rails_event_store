module Orders
  class RemoveItemFromBasket < Command
    attribute :order_id, Types::UUID
    attribute :product_id, Types::Coercible::Integer
  end
end
