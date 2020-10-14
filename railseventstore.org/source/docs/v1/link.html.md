---
title: Linking to stream
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
    event_store.publish(
      OrderPlaced.new(data: { id: @id }),
      stream_name: stream_name
    )
  end

  private

  def event_store
    Rails.configuration.event_store
  end

  def stream_name
    "Order$#{@id}"
  end
end

order = Order.new('68a5214d-3194-4cfd-8997-5033bcb7e68a')
order.place
```

Now imagine you'd like to see in one place all facts about placed orders in Jan 2018. This can be done processing all events collected so far in the event store. Each time you want such report, it runs from beginning — filtering irrelevant events out.

For repeated use it would be much better process events only once and store them in some sort of a collection — the stream:

```ruby
order_placed = RailsEventStore::Projection
  .from_all_streams
  .init( -> { })
  .when([OrderPlaced], ->(state, event) {
    time = event.metadata[:timestamp]
    if time.year == 2018 && time.month == 1
      event_store.link(
        event.event_id,
        stream_name: 'OrderPlaced$2018-01',
        expected_version: :any
      )
    end
  })

order_placed.run(event_store)
```

Now going for `OrderPlaced` events in January is as simple as reading:

```ruby
event_store.read.stream('OrderPlaced$2018-01').to_a
```

Linking can be even managed as soon as event is published, via event handler:

```ruby
class OrderPlacedReport
  def call(event)
    event_store.link(
      event.event_id,
      stream_name: stream_name(event.metadata[:timestamp]),
      expected_version: :any
    )
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

Linking also follows the same rules regarding [expected_version](/docs/v1/expected_version/) as publishing an event for the first time.
