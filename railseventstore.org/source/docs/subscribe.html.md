# Subscribing to events

To subscribe to events in Rails Event Store you need to use `#subscribe` method.

## Classic subscriptions

To subscribe to events publication in a classic way, you can use a version of `#subscribe` which does not accept the block. It accepts two arguments:

* `subscriber` (event handler) - which can be a function-like object. That means it needs to respond to the `#call` method. This way both normal objects and `lambda` expressions are supported.
* `event_types` - which is an array of event types. Your subscriber will get notified only when events of types listed here will be published.

An example usage with the object event handler:

```ruby
class InvoiceReadModel
  def call(event)
    # Process an event here.
  end
end

subscriber = InvoiceReadModel.new
event_store.subscribe(subscriber, [InvoiceCreated, InvoiceUpdated])
```

You can use `Proc` objects or `lambda`s here:

```ruby
invoice_read_model_processing = -> (event) {
  # Process an event here..
}

send_invoice_email = Proc.new do |event|
  # Process an event here.
end

event_store.subscribe(invoice_read_model_processing, [InvoiceCreated, InvoiceUpdated])
event_store.subscribe(send_invoice_email, [InvoiceAccepted])
```

You can also subscribe for all event types at once. It is especially useful for logging or debugging events:

```ruby
class EventsLogger
  def initialize(logger)
    @logger = logger
  end

  def call(event)
    logger.info("#{event.class.to_s} published. Data: #{event.data.inspect}")
  end

  private
  attr_reader :logger
end

event_store.subscribe_to_all_events(EventsLogger.new(Rails.logger))
```

> In early versions of Rails Event Store event handlers (subscribers) needed to have `#handle_event` method. While it is still supported, it will be removed in future. For your convenience, it now gives a deprecation warning.

## Dynamic (one-shot) subscriptions

Rails Event Store supports dynamic, one-shot, anonymous subscriptions for events. One-shot means that after publishing an event in which such subscriber is interested it gets unsubscribed automatically.

You can achieve such behaviour by passing the block to the `#subscribe` method. Then it accepts only one argument - `event_types` which is an array of event types for which subscriber (block) will get invoked.

This is useful in many use cases, for example it can be used to implement a saga pattern:

```ruby
module MissingShippingDetails
  class State
    def self.from_status(status)
      # ...
    end
  end

  class AddressNotProvided
    def process(saga, event)
      # ...
    end
  end

  # ...
end

class MissingShippingDetailsSaga < ActiveRecord::Base
  include MissingShippingDetails

  def state
    @state ||= State.from_status(status)
  end

  def subscribe(event_store)
    return if state.final?
    event_store.subscribe(state.awaited_events) do |event|
      # Sagas are basically state machines. Try to change the state...
      @state = state.process(self, event)
      @status = @state.name
      # ... and resubscribe (maybe state changed, so other events will be awaited)
      subscribe(event_store)
    end
  end

  # ...
end
```

Remember that subscriptions are one-shot. If you want to still pass a block without having one-shot behaviour, you can use classical subscription pattern. Remember blocks are `Proc`s under the hood!
