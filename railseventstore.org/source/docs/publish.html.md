# Publishing events

## Creating new event

Firstly you have to define own event model extending `RailsEventStore::Event` class.

```ruby
class OrderPlaced < RailsEventStore::Event
end

# or

OrderPlaced = Class.new(RailsEventStore::Event)
```

Then you can use `publish_event` or `publish_events` method from.

```ruby
stream_name = "order_1"
event = OrderPlaced.new(data: {
  order_id: 1,
  order_data: "sample",
  festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
})

#publishing an event for a specific stream
event_store.publish_event(event, stream_name: stream_name)

#publishing a global event
event_store.publish_event(event)
```

## Creating new event with optimistic locking

```ruby
class OrderPlaced < RailsEventStore::Event
end
```

```ruby
event = OrderPlaced.new(data: {
  order_id: 1,
  order_data: "sample",
  festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
})

event_store.publish_event(
  event,
  stream_name: "order_1",
  expected_version: 3 # the position of the last
                      # event in this stream
)
```

## Appending an event to stream

In order to skip handlers you can just append an event to a stream.

```ruby
event = OrderPlaced.new(data: {
  order_id: 1,
  order_data: "sample",
  festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
})
event_store.append_to_stream(
  event,
  stream_name: "order_1"
)
```