---
title: Event handlers - Subscribing to events
---

To subscribe a handler to events in Rails Event Store you need to use `#subscribe` method on `RailsEventStore::Client`

Depending on where you decided to keep the configuration that would usually be in `config/application.rb` or `config/initializers/rails_event_store.rb` or one of environment files (`config/environments/*.rb`).

```ruby
# config/application.rb
module YourAppName
  class Application < Rails::Application
    config.to_prepare do
      Rails.configuration.event_store = event_store = RailsEventStore::Client.new
      event_store.subscribe(OrderNotifier.new, to: [OrderCancelled])
    end
  end
end
```

#### Removing subscriptions

When you define a new subscription by `subscribe` method execution it will return a lambda that allows to remove defined subscription.

```ruby
Rails.configuration.event_store = event_store = RailsEventStore::Client.new
unsubscribe = event_store.subscribe(OrderNotifier.new, to: [OrderCancelled])
# ...and then when subscription is no longer needed
unsubscribe.call
```

Unsubscribe lambda will remove all subscriptions defined by `subscribe` method, when you defined subscription as:

```ruby
unsubscribe = event_store.subscribe(InvoiceReadModel.new, to: [InvoiceCreated, InvoiceUpdated])
```

and then execute returned lambda both subscriptions will be removed.

It you need temporary subscription to be defined [read more here](/docs/v1/subscribe/#temporary-subscriptions).


## Synchronous handlers

To subscribe to events publication, you can use `#subscribe` method. It accepts two arguments:

- `subscriber` (an event handler) - which can be a function-like object. That means it needs to respond to the `#call` method. This way both normal objects and `lambda` expressions are supported. A block of code can also be passed as a subscriber (`&subscriber`)
- `to:` - which is an array of event types. Your subscriber gets notified only when events of types listed here are be published.

An example usage with the object event handler:

```ruby
class InvoiceReadModel
  def call(event)
    # Process an event here.
  end
end

subscriber = InvoiceReadModel.new
event_store.subscribe(subscriber, to: [InvoiceCreated, InvoiceUpdated])
```

You can use `Proc` objects or `lambda`s in 3 ways:

```ruby
event_store.subscribe(to: [InvoicePrinted]) do |event|
  # Process an event here...
end
```

```ruby
invoice_read_model = -> (event) {
  # Process an event here...
}

event_store.subscribe(invoice_read_model, to: [InvoiceCreated, InvoiceUpdated])
```

```ruby
send_invoice_email = Proc.new do |event|
  # Process an event here...
end

event_store.subscribe(send_invoice_email,to: [InvoiceAccepted])
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
event_store.subscribe(SyncHandler.new, to: [OrderPlaced])
```

```ruby
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

<h3 id="fresh-handler-state">Fresh handler state</h3>

If you subscribe an instance of a class (`SyncHandler.new`), the same object is going to be called with new events.

```ruby
class SyncHandler
  def call(event)
  end
end
```

```ruby
handler = SyncHandler.new
event_store.subscribe(handler, to: [OrderPlaced])
```

```ruby
event_store.publish(OrderPlaced.new)
# handler is called

event_store.publish(OrderPlaced.new)
# handler is called again
```

This can be problematic, especially if you use memoization (the `@ivar ||= ...` pattern).

```ruby
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

because subsequent events would read the same `@customer_id` which was memoized when the handler was processing a previous event. To avoid that problem, you can subscribe a class (`SyncHandler`), and a new instance of that class will be created for every published event.

```ruby
event_store.subscribe(SyncHandler, to: [OrderPlaced])
```

```ruby
event_store.publish(OrderPlaced.new(data: {customer_id: 2}))
# SyncHandler.new.call is invoked (instance A)

event_store.publish(OrderPlaced.new(data: {customer_id: 3}))
# SyncHandler.new.call is invoked (instance B)
```

### When are sync handlers executed?

Those handlers are executed immediately after events are stored in the DB.

```ruby
ActiveRecord::Base.transaction do
  order = Order.new(...).save!
  event_store.publish(
    OrderPlaced.new(data:{order_id: order.id}),
    stream_name: "Order-#{order.id}"
  )
  # Sync handlers executed here
end
```

## Subscribe for all event types

You can also subscribe for all event types at once. It is especially useful for logging or debugging events. Use `subscribe_to_all_events(subsriber1, to:, &subscriber2)` method for that.

```ruby
class EventsLogger
  def initialize(logger)
    @logger = logger
  end

  def call(event)
    logger.info("#{event.event_type} published. Data: #{event.data.inspect}")
  end

  private
  attr_reader :logger
end

event_store.subscribe_to_all_events(EventsLogger.new(Rails.logger))
event_store.subscribe_to_all_events do |event|
  puts event.inspect
end
```

## Temporary subscriptions

Rails Event Store supports temporary (dynamic, one-shot) subscriptions for events. The subscriber gets unsubscribed automatically at the end of the provided block.

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
event_store.within do
  Import.new.run(file)
end.subscribe(results, to: event_types).call
```

This can be useful also in controllers:

```ruby
class OperationsController < ApplicationController
  def create
    event_store.within do
      Operation.new.run(file)
    end.subscribe(to: [OperationSucceeded]) do
      redirect_to results_index_path
    end.subscribe(to: [OperationFailed]) do
      render :new
    end.call
  end
end
```

Temporarily subscribing to all events is also supported.

```ruby
event_store.within do
  Import.new.run(file)
end.subscribe_to_all_events(EventsLogger).subscribe_to_all_events do |event|
  puts event.inspect
end.call
```

You start the temporary subscription by providing a block `within` which the subscriptions will be active. Then you can chain `subscribe` and `subscribe_to_all_events` as many times as you want to register temporary subscribers. When you are ready call `call` to evaluate the provided block with the temporary subscriptions.

<h2 id="async-handlers">Async handlers</h2>

It's possible to also subscribe asynchronous handlers to events. To implement asynchronous dispatcher for a background jobs library of your choice firstly you need to implement scheduler class that will enqueue asynchrounous handlers as background jobs.

The sample `CustomScheduler` could be implemented as:

```ruby
class CustomScheduler
  # method doing actual schedule
  def call(klass, serialized_record)
    klass.perform_async(serialized_record.to_h)
  end

  # method which is checking whether given subscriber is correct for this scheduler
  def verify(subscriber)
    Class === subscriber && subscriber.respond_to?(:perform_async)
  end
end
```

You can also use our [`scheduler_lint`](https://github.com/RailsEventStore/rails_event_store/blob/master/ruby_event_store/lib/ruby_event_store/spec/scheduler_lint.rb) for more confidence that your scheduler is written correctly.

Then you have to initialize `RailsEventStore::Client` using asynchronous dispatcher with your custom scheduler:

```ruby
event_store = RailsEventStore::Client.new(
  dispatcher: RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: CustomScheduler.new)
)
```

Often you will want to be able to specify both asynchronous and synchronous dispatchers. In that case, you can use `ComposedDispatcher`, which accepts arbitrary number of dispatchers and dispatch the event to the first subscriber which is accepted (by `verify` method) by the dispatcher. This is also our default configuration in `RailsEventStore`.

```ruby
event_store = RailsEventStore::Client.new(
  dispatcher: RubyEventStore::ComposedDispatcher.new(
    RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: CustomScheduler.new), # our asynchronous dispatcher, which expects that subscriber respond to `perform_async` method
    RubyEventStore::Dispatcher.new # regular synchronous dispatcher
  )
)
```

RailsEventStore provides [implementation of a scheduler](https://github.com/RailsEventStore/rails_event_store/blob/master/rails_event_store/lib/rails_event_store/active_job_scheduler.rb) for `ActiveJob` library.
In that case async handlers are just background jobs implemented as:

```ruby
class SendOrderEmail < ActiveJob::Base
  def perform(payload)
    event = event_store.deserialize(payload)
    email = event.data.fetch(:customer_email)
    OrderMailer.notify_customer(email).deliver_now!
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end

event_store = RailsEventStore::Client.new
event_store.subscribe(SendOrderEmail, to: [OrderPlaced])
```

You can also use `RailsEventStore::AsyncHandler` module that will deserialize the event for you:

```ruby
class SendOrderEmail < ActiveJob::Base
  prepend RailsEventStore::AsyncHandler

  def perform(event)
    email = event.data.fetch(:customer_email)
    OrderMailer.notify_customer(email).deliver_now!
  end
end

event_store = RailsEventStore::Client.new
event_store.subscribe(SendOrderEmail, to: [OrderPlaced])
```

### When are async handlers scheduled?

The default behaviour and examples above use `RubyEventStore::ImmediateAsyncDispatcher`, which schedule handlers immediately after events are stored in the database.

```ruby
ActiveRecord::Base.transaction do
  order = Order.new(...).save!
  event_store.publish(
    OrderPlaced.new(data:{order_id: order.id}),
    stream_name: "Order-#{order.id}"
  )
  # Async handlers such as SendOrderEmail scheduled here
end
```

It means that when your `ActiveJob` adapter (such as sidekiq or resque) is using non-SQL store your handler might get called before the whole transaction is committed or when the transaction was rolled-back.

### Scheduling async handlers after commit

You can configure your dispatcher slightly different, to schedule async handlers after commit. Note the usage of `RailsEventStore::AfterCommitAsyncDispatcher` instead of `RubyEventStore::ImmediateAsyncDispatcher`.

```ruby
class SendOrderEmail < ActiveJob::Base
  prepend RailsEventStore::AsyncHandler

  def perform(event)
    email = event.data.fetch(:customer_email)
    OrderMailer.notify_customer(email).deliver_now!
  end
end

event_store = RailsEventStore::Client.new(
  dispatcher: RubyEventStore::ComposedDispatcher.new(
    RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new),
    RubyEventStore::Dispatcher.new
  )
)

event_store.subscribe(SendOrderEmail, to: [OrderPlaced])

# ...

ActiveRecord::Base.transaction do
  order = Order.new(...).save!
  event_store.publish(
    OrderPlaced.new(data:{order_id: order.id}),
    stream_name: "Order-#{order.id}"
  )
end
# Async handlers such as SendOrderEmail scheduled here, after transaction is committed
```
