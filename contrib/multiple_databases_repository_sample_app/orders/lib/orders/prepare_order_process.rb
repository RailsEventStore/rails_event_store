module Orders
  class PrepareOrderProcess
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
        @data = { amount: 0.to_d }
        events.each{|e| apply(e)}
      end

      def done?
        data[:amount] > 0 && data[:order_id]
      end

      def command
        Orders::PlaceOrder.new(**data)
      end

      private
      attr_reader :data

      def apply(event)
        case event
          when Orders::ItemAddedToBasket
            data[:amount] += 10.to_d
          when Orders::ItemRemovedFromBasket
            data[:amount] -= 10.to_d
          when Orders::OrderSubmitted
            data.merge!(event.data.slice(
              :order_id,
              :order_number,
              :customer_id,
              :delivery_address_id,
              :payment_method_id
            ))
          else
            raise ArgumentError.new("Not suported domain event")
        end
      end
    end

    def with_linked(event)
      stream = "PreparationProcess$#{event.order_id}"
      event_store.link(
        event.event_id,
        stream_name: stream
      )
      yield State.new(event_store.read.stream(stream))
    rescue RubyEventStore::EventDuplicatedInStream
    end
  end
end
