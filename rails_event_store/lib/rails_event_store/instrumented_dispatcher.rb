require 'active_support/notifications'

module RailsEventStore
  class InstrumentedDispatcher
    def call(subscriber, event)
      raise InvalidHandler.new(subscriber) unless subscriber.respond_to?(:call)

      ActiveSupport::Notifications.instrument("dispatch.rails_event_store", event: event, subscriber: subscriber) do
        subscriber.call(event)
      end
    end
  end
end
