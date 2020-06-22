module Shipping
  class PackageShipped < Event
    attribute :order_id, Types::UUID
    attribute :customer_id, Types::ID
    attribute :delivery_address_id, Types::ID
    attribute :tracking_number, Types::String
    attribute :estimated_delivery_date, Types::JSON::Date
  end
end
