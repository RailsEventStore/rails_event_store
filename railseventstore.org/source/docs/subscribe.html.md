# Event handlers - Subscribing to events

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

Rails Event Store supports dynamic, one-shot subscriptions for events. The subscriber gets unsubscribed automatically at the end of the provided block.

```ruby
class CountImportResults
  def initialize()
    @ok = 0
    @error = 0
  end

  def call(event)
    case event
    when ProductImported
      @ok += 1
    when ProductImportFailed
      @error += 1
    else
      raise ArgumentError
    end
  end
end

class Import
  def run(file)
    CSV.parse(file) do |row|
      if row_imported(row)
        event_store.publish(ProductImported.new(...))
      else
        event_store.publish(ProductImportFailed.new(...))
      end
    end
  end
end

results = CountImportResults.new
event_types = [ProductImported, ProductImportFailed]
event_store.subscribe(results, event_types) do
  Import.new.run(file)
end
```
