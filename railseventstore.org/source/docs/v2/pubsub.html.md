---
title: Using Rails Event Store as a pub-sub message bus
---

## Defining an event

Firstly, you have to define an event class extending `RailsEventStore::Event` class.

```ruby
class OrderCancelled < RailsEventStore::Event
end
```

## Configuring RES client

```ruby
# config/application.rb
module YourAppName
  class Application < Rails::Application
    config.to_prepare do
      Rails.configuration.event_store = RailsEventStore::Client.new
    end
  end
end
```

## Publishing

```ruby
class CancelOrdersService
  def call(order_id, user_id)
    order = Order.find_by!(
      customer_id: user_id,
      order_id: order_id,
    )
    order.cancel!
    event_store.publish(
      OrderCancelled.new(data: {
        order_id: order.id,
        customer_id: order.customer_id,
      }),
      stream_name: "Order-#{order.id}"
    )
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
```

Any class with access to `Rails.configuration.event_store` can publish events to subscribed listeners (aka subscribers or handlers). That can be a Rails model or a service object. Whatever you like.

Listeners subscribe, at runtime (or during configuration phase) to the publisher.

## Subscribing

### Objects

Any object responding to `call` can be subscribed as an event handler.

```ruby
cancel_order = CancelOrder.new
event_store  = Rails.configuration.event_store
listener     = OrderNotifier.new

event_store.within do
  cancel_order.call(order_id, user_id)
end.subscribe(listener, to: [OrderCancelled]).call
```

The listener would need to implement the `call` method. If it needs to handle more than one event, it can distinguish them based on their class.

```ruby
class OrderNotifier
  def call(event)
    order_id = order.data.fetch(:order_id)
    case event
    when OrderCancelled
      # notify someone...
    else
      raise "not supported event #{event.inspect}"
    end
  end
end
```

### Blocks

```ruby
cancel_order = CancelOrder.new
event_store  = Rails.configuration.event_store

event_store.within do
  cancel_order.call(order_id, user_id)
end.subscribe(to: [OrderCancelled]) do |event|
  Rails.logger.warn(event.inspect)
end.call
```

### Global event subscribers (a.k.a. handlers/listeners)

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

Make sure to read about [fresh handler state](/docs/v1/subscribe//#fresh-handler-state) to avoid potential issues from using the same listener for many published events.

## Handling Events Asynchronously

Asynchronous handlers are described in [Async handlers section](/docs/v1/subscribe//#async-handlers)
