module Shipping
  class ShippingProcess
    def initialize(event_store, bus)
      @event_store = event_store
      @bus = bus
    end

    def call(event)
      with_linked(event) do |state|
        bus.call(state.command) if state.done?
      end
    end

    private
    attr_reader :event_store, :bus

    class State < ApplicationRecord
      self.table_name = :shipping_process_state
      serialize :states, Array

      def intialize
        self.states = []
      end

      def done?
        states.include?(:placed) && states.include?(:paid)
      end

      def command
        Shipping::ShipPackage.new(
          order_id: order_id,
          customer_id: customer_id,
          delivery_address_id: delivery_address_id,
        )
      end

      def apply(event)
        case event
          when Shipping::OrderPlaced
            self.customer_id = event.customer_id
            self.delivery_address_id = event.delivery_address_id
            states << :placed
          when Shipping::OrderPaid
            states << :paid
          else
            raise ArgumentError.new("Not suported domain event")
        end
      end
    end

    def with_linked(event)
      State.transaction do
        state = State.lock.find_or_create_by!(order_id: event.order_id)
        state.apply(event)
        state.save!
        yield state
      end
    end
  end
end
