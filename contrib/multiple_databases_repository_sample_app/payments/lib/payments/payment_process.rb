module Payments
  class PaymentProcess
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
        @state = nil
        @action = nil
        events.each{|e| apply(e)}
      end

      def done?
        !!action
      end

      def command
        case action
          when :complete
            Payments::CompletePayment.new(**data)
          when :release
            Payments::ReleasePayment.new(**data.slice(:transaction_id))
          else
            raise ArgumentError.new("Unknown action")
          end
      end

      private
      attr_reader :data, :state, :action

      def apply(event)
        case event
          when Payments::PaymentAuthorized
            data[:transaction_id] = event.transaction_id
            data[:order_id] = event.order_id
            @state = :authorized
          when Payments::PaymentCaptured
            @action = :complete if authorized?
            @state = :captured
          when Payments::PaymentExpired
            @action = :release if authorized?
            @state = :expired
          else
            raise ArgumentError.new("Not suported domain event")
        end
      end

      def authorized?
        state == :authorized
      end
    end

    def with_linked(event)
      stream = "PaymentProcess$#{event.transaction_id}"
      event_store.link(
        event.event_id,
        stream_name: stream
      )
      yield State.new(event_store.read.stream(stream))
    rescue RubyEventStore::EventDuplicatedInStream
    end
  end
end
