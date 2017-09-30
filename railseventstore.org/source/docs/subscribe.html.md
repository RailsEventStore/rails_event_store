# Event handlers - Subscribing to events

To subscribe a handler to events in Rails Event Store you need to use `#subscribe` method.

## Synchronous handlers

To subscribe to events publication, you can use `#subscribe` method. It accepts two arguments:

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

### Handling exceptions

If your synchronous handlers raise an exception, it might bubble up and cause problems such as reverting a transaction.

```ruby
class SyncHandler
  def call(event)
    # ...
    raise StandardError, "ups, something went wrong"
  end
end
```

```ruby
event_store.subscribe(SyncHandler.new, [OrderPlaced])
```

```
ActiveRecord::Base.transaction do
  event_store.publish(OrderPlaced.new)
  # sync handlers executed here
  # exception will bubble up
  # and rollback the transaction
end
```

If you don't want your event handlers to cause such potential problems, just swallow the exceptions and send them to your exception tracker.

```ruby
class SyncHandler
  def call(event)
    # ...
  rescue => e
    ExceptionTracker.notify(e)
  end
end
```

### Fresh handler state

If you subscribe an instance of a class, the same object is going to be called with new events.

```ruby
class SyncHandler
  def call(event)
  end
end
```

```ruby
handler = SyncHandler.new
event_store.subscribe(handler, [OrderPlaced])
```

```ruby
event_store.publish_event(OrderPlaced.new)
# handler is called

event_store.publish_event(OrderPlaced.new)
# handler is called again
```

This can be problematic, especially if you use memoization.

```
class SyncHandler
  def call(event)
    Rails.logger.warn("Order placed by #{customer_id(event)}")
    Stats.increase("orders-#{customer_id(event)}", 1)
  end

  private

  def customer_id(event)
    @customer_id ||= event.data.fetch(:customer_id)
  end
end
```

because subsequent events would read the same `@customer_id` which was memoized by a previous event. To avoid that problem, you can subscribe a class, and a new instance will be created for every event.

```ruby
event_store.subscribe(SyncHandler, [OrderPlaced])
```

```ruby
event_store.publish_event(OrderPlaced.new)
# SyncHandler.new is called (instance A)

event_store.publish_event(OrderPlaced.new)
# SyncHandler.new is called (instance B)
```

### When are sync handlers executed?

Those handlers are executed immediately after events are stored in DB.

```ruby
ActiveRecord::Base.transction do
  order = Order.new(...).save!
  event_store.publish_event(
    OrderPlaced.new(data:{order_id: order.id}),
    stream_name: "Order-#{order.id}"
  )
  # Sync handlers executed here
end
```

## Subscribe for all event types

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

## Async handlers

It's possible to also subscribe async handlers to events. Async handlers are just background jobs implemented with `ActiveJob`. However, you need to configure `RailsEventStore` to use `ActiveJobDispatcher`.

```ruby
class SendOrderEmail < ActiveJob::Base
  def perform(event)
    event = YAML.load(event)
    email = event.data.fetch(:customer_email)
    OrderMailer.notify_customer(email).deliver_now!
  end
end

event_store = RailsEventStore::Client.new(
  event_broker: RailsEventStore::EventBroker.new(
    dispatcher: RailsEventStore::ActiveJobDispatcher.new
  )
)

event_store.subscribe(SendOrderEmail, [OrderPlaced])
```

If a subscribed class does not inherit from `ActiveJob::Base` or anything responding to `#call` method is provided as first argument, it will be considered a synchronous handler.

### When are async handlers scheduled?

Those async handlers are scheduled immediately after events are stored in DB.

```ruby
ActiveRecord::Base.transction do
  order = Order.new(...).save!
  event_store.publish_event(
    OrderPlaced.new(data:{order_id: order.id}),
    stream_name: "Order-#{order.id}"
  )
  # Async handlers such as SendOrderEmail scheduled here
end
```

That means when your `ActiveJob` adapter (such as sidekiq or resque)
is using non-SQL store, your handler might be called before the
whole transaction is committed or when the transaction was rolled-back.

### Scheduling async handlers after commit

You can configure your dispatcher slightly different, to schedule async handlers after commit.

```ruby
class SendOrderEmail < ActiveJob::Base
  def perform(event)
    event = YAML.load(event)
    email = event.data.fetch(:customer_email)
    OrderMailer.notify_customer(email).deliver_now!
  end
end

event_store = RailsEventStore::Client.new(
  event_broker: RailsEventStore::EventBroker.new(
    dispatcher: RailsEventStore::ActiveJobDispatcher.new(
      proxy_strategy: RailsEventStore::AsyncProxyStrategy::AfterCommit.new
    )
  )
)

event_store.subscribe(SendOrderEmail, [OrderPlaced])
```

```ruby
ActiveRecord::Base.transction do
  order = Order.new(...).save!
  event_store.publish_event(
    OrderPlaced.new(data:{order_id: order.id}),
    stream_name: "Order-#{order.id}"
  )
end
# Async handlers such as SendOrderEmail scheduled here
```