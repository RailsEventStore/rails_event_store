module Payments
  class OnCompletePayment
    def initialize(event_store)
      @event_store = event_store
    end

    def call(command)
      event_store.publish(Payments::PaymentCompleted.new(**command))
    end

    private
    attr_reader :event_store
  end
end
