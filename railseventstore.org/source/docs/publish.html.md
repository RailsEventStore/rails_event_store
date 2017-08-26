# Publishing events

## Creating new event

Firstly you have to define own event model extending `RailsEventStore::Event` class.

```ruby
class OrderPlaced < RailsEventStore::Event
end

# or

OrderPlaced = Class.new(RailsEventStore::Event)
```

```ruby
stream_name = "order_1"
event = OrderPlaced.new(data: {
          order_data: "sample",
          festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
        })
#publishing event for specific stream
client.publish_event(event, stream_name: stream_name)

#publishing global event. In this case stream_name is 'all'.
client.publish_event(event)
```

## Creating new event with optimistic locking

```ruby
class OrderPlaced < RailsEventStore::Event
end
```

```ruby
stream_name = "order_1"
event = OrderPlaced.new(data: {
          order_data: "sample",
          festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
        })
expected_version = "850c347f-423a-4158-a5ce-b885396c5b73" #last event_id
client.publish_event(event, stream_name: stream_name, expected_version: expected_version)
```

## Appending event to stream

In order to skip handlers you can just append event to a stream.

```ruby
stream_name = "order_1"
event = OrderPlaced.new(data: {
          order_data: "sample",
          festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
        })
client.append_to_stream(event, stream_name: stream_name)
```
