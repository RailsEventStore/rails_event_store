module Shipping
  class ShipPackage < Command
    attribute :order_id, Types::UUID
    attribute :customer_id, Types::ID
    attribute :delivery_address_id, Types::ID
  end
end
