---
title: Linking to stream
sidebar_position: 4
---

An event, once published, can live in more than one stream. Such quality comes useful in order to persistently group events of particular kinds.

Let's assume you've got an `Order` aggregate of `68a5214d-3194-4cfd-8997-5033bcb7e68a` id and an `OrderPlaced` event. By convention `OrderPlaced` event will be published in `Order$68a5214d-3194-4cfd-8997-5033bcb7e68a` stream:

```ruby
OrderPlaced = Class.new(RailsEventStore::Event)

class Order
  def initialize(id)
    @id = id
  end

  def place
    event_store.publish(OrderPlaced.new(data: { id: @id }), stream_name: stream_name)
  end

  private

  def event_store
    Rails.configuration.event_store
  end

  def stream_name
    "Order$#{@id}"
  end
end

order = Order.new("68a5214d-3194-4cfd-8997-5033bcb7e68a")
order.place
```

Now imagine you'd like to see in one place all facts about placed orders in Jan 2018. This can be done processing all events collected so far in the event store. Each time you want such report, it runs from beginning — filtering irrelevant events out.

For repeated use it would be much better to process events only once and store them in some sort of a collection — the stream:

```ruby
order_placed =
  RailsEventStore::Projection
    .from_all_streams
    .init(-> {  })
    .when(
      [OrderPlaced],
      ->(state, event) do
        time = event.metadata[:timestamp]
        if time.year == 2018 && time.month == 1
          event_store.link(event.event_id, stream_name: "OrderPlaced$2018-01", expected_version: :any)
        end
      end,
    )

order_placed.run(event_store)
```

Now going for `OrderPlaced` events in January is as simple as reading:

```ruby
event_store.read.stream("OrderPlaced$2018-01").to_a
```

Linking can be even managed as soon as event is published, via event handler:

```ruby
class OrderPlacedReport
  def call(event)
    event_store.link(event.event_id, stream_name: stream_name(event.metadata[:timestamp]), expected_version: :any)
  end

  private

  def stream_name(timestamp)
    "OrderPlaced$%4d-%02d" % [timestamp.year, timestamp.month]
  end

  def event_store
    Rails.configuration.event_store
  end
end

subscriber = OrderPlacedReport.new
event_store.subscribe(subscriber, [OrderPlaced])
```

It is worth remembering that linking an event does not trigger event handlers and you cannot link same event more than once in a given stream.

Linking also follows the same rules regarding [expected_version](./expected-version) as publishing an event for the first time.

## Available linking classes

RailsEventStore offers a set of linking classes that can be used to link events to streams. Those classes are:

  * `RailsEventStore::LinkByMetadata` - links events to stream built on specified metadata key and value,
  * `RailsEventStore::LinkByCorrelationId` - links events to stream by event's correlation id,
  * `RailsEventStore::LinkByCausationId` - links events to stream by event's causation id,
  * `RailsEventStore::LinkByEventType` - links events to stream by event's type

### Usage

#### Linking by metadata

In order to link by metadata you need to provide a metadata key that you're interested in. The following example shows how to
link all events by the `tenant_id` metadata key:

```ruby
  event_store.subscribe_to_all_events(LinkByMetadata.new(event_store: event_store, key: :tenant_id))
```

The resulting stream for tenant with id = 123 would be `$by_tenant_id_123`

#### Linking by correlation and causation ids

In order to link by correlation and causation ids you simply call

```ruby
  event_store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
  event_store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
```

The resulting streams would be `$by_correlation_id_123` and `$by_causation_id_123` respectively.

#### Linking by event type

In order to link by events types use following code:

```ruby
  event_store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
```

The resulting stream for `OrderPlaced` event would be `$by_event_type_OrderPlaced`

#### Custom prefix
Instead of using `$by_{class}` prefix you can use your own prefix by passing it as an argument to the linking class:

```ruby
  event_store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new(prefix: 'my_prefix'))
```

The resulting stream for `OrderPlaced` event would be `my_prefix_OrderPlaced`.

It works analogically for other linking classes.