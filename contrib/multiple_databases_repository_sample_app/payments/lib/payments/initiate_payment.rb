module Payments
  class InitiatePayment
    def initialize(bus)
      @bus = bus
    end

    def call(event)
      @bus.call(AuthorizePayment.new(**event.data.merge(
        transaction_id: SecureRandom.hex(16),
      )))
    end
  end
end
