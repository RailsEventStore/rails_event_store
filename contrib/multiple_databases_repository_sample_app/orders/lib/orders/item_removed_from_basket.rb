module Orders
  class ItemRemovedFromBasket < Event
    attribute :order_id,   Types::UUID
    attribute :product_id, Types::ID
  end
end
