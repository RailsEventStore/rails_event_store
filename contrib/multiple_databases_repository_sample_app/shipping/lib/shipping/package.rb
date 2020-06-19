module Shipping
  class Package
    include AggregateRoot

    def ship_to(customer_id, address_id)
      apply(PackageShipped.new(data: {
        customer_id: customer_id,
        delivery_address_id: address_id,
        tracking_number: SecureRandom.hex(16),
        estimated_delivery_date: 2.days.from_now.to_date,
      }))
    end

    private

    on PackageShipped do |event|
      @state = :ready
      @tracking_number = event.tracking_number
    end
  end
end

