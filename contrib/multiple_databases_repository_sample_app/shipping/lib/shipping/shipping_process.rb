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

    class State
      def initialize(events)
        @data = {}
        @state = []
        events.each{|e| apply(e)}
      end

      def done?
        state.include?(:placed) && state.include?(:paid)
      end

      def command
        Shipping::CompleteShipping.new(**data)
      end

      private
      attr_reader :data, :state

      def apply(event)
        case event
          when Shipping::OrderPlaced
            data[:order_id] = event.order_id
            data[:customer_id] = event.customer_id
            data[:delivery_address_id] = event.delivery_address_id
            @state << :placed
          when Shipping::OrderPaid
            @state << :paid
          else
            raise ArgumentError.new("Not suported domain event")
        end
      end
    end

    def with_linked(event)
      stream = "ShippingProcess$#{event.order_id}"
      event_store.link(
        event.event_id,
        stream_name: stream
      )
      yield State.new(event_store.read.stream(stream))
    rescue RubyEventStore::EventDuplicatedInStream
    end
  end
end
