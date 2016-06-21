# Creating new event

Firstly you have to define own event model extending `RailsEventStore::Event` class.

```ruby
class OrderCreated < RailsEventStore::Event
end

# or

OrderCreated = Class.new(RailsEventStore::Event)
```

```ruby
stream_name = "order_1"
event = OrderCreated.new(
          data: "sample",
          event_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
        )
#publishing event for specific stream
client.publish_event(event, stream_name)

#publishing global event. In this case stream_name is 'all'.
client.publish_event(event)
```

# Creating new event with optimistic locking:

```ruby
class OrderCreated < RailsEventStore::Event
end
```

```ruby
stream_name = "order_1"
event = OrderCreated.new(
          data: "sample",
          event_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
        )
expected_version = "850c347f-423a-4158-a5ce-b885396c5b73" #last event_id
client.publish_event(event, stream_name, expected_version)
```

# Appending event to stream

To prevent execute handlers you can just append event to a stream.

```ruby
stream_name = "order_1"
event = OrderCreated.new(
          data: "sample",
          event_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
        )
client.append_to_stream(event, stream_name)
```