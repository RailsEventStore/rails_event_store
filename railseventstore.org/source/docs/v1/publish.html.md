---
title: Publishing events
---

## Defining an event

Firstly you have to define your own event model extending `RailsEventStore::Event` class.

```ruby
class OrderPlaced < RailsEventStore::Event
end

# or

OrderPlaced = Class.new(RailsEventStore::Event)
```

## Publishing an event

Then you can use `publish` method.

```ruby
stream_name = "order_1"
event = OrderPlaced.new(data: {
  order_id: 1,
  order_data: "sample",
  festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
})

#publishing an event for a specific stream
event_store.publish(event, stream_name: stream_name)
```

## Publishing an event with optimistic locking

Publishing an event with optimistic locking requires providing explicitly `expected_version` parameter.

```ruby
event = OrderPlaced.new(data: {
  order_id: 1,
  order_data: "sample",
  festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
})

event_store.publish(
  event,
  stream_name: "order_1",
  expected_version: 3 # the position of the last
                      # event in this stream
)
```

## expected_version

Providing `expected_version` is optional. The default value is `:any`.
Allowed values are:

- `:any`:
- `Integer` such as `-1, 0, 1, 2, 3...`
- `:auto`

For more information about when should you use which one, read [expected_version explained](/docs/v1/expected_version/)

## No stream

Providing `stream_name` is optional (but recommended).

```ruby
event_store.publish(event)
```

If you don't provide the `stream_name` you can only read the events with `read.to_a` and `read.backward.to_a` queries (without filtering on particular stream name).

## Appending an event to stream

In order to skip handlers you can append an event to a stream. This won't trigger the subscribed listeners.

```ruby
event = OrderPlaced.new(data: {
  order_id: 1,
  order_data: "sample",
  festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
})

event_store.append(
  event,
  stream_name: "order_1"
)
```
