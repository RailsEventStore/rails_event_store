module Payments
  class InitiatePayment
    def initialize(bus)
      @bus = bus
    end

    def call(event)
      bus.call(AuthorizePayment.new(
        transaction_id: SecureRandom.hex(16),
        order_id: event.data.order_id
      ))
    end
  end
end
