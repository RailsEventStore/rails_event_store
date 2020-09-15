module Shipping
  class OnShipPackage
    include CommandHandler

    def call(command)
      with_aggregate(Package.new(command.order_id), command.order_id) do |package|
        package.ship_to(
          command.customer_id,
          command.delivery_address_id,
        )
      end
    end
  end
end
