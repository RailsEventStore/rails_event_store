## Reading stream's events forward in batch - starting from first event

```ruby
stream_name = "order_1"
count = 40
client.read_events_forward(stream_name, start: :head, count: count)
```

In this case `:head` means first event of the stream.

## Reading stream's events forward in batch - staring from given event

```ruby
# last_read_event is any domain event read or published by rails_event_store

stream_name = "order_1"
start = last_read_event.event_id
count = 40
client.read_events_forward(stream_name, start: start, count: count)
```

## Reading stream's events backward in batch

As in examples above, just use `read_events_backward` instead of `read_events_forward`.
In this case `:head` means last event of the stream.

## Reading all events from stream forward

This method allows us to load all stream's events ascending.

```ruby
stream_name = "order_1"
client.read_stream_events_forward(stream_name)
```

## Reading all events from stream backward

This method allows us to load all stream's events descending.

```ruby
stream_name = "order_1"
client.read_stream_events_backward(stream_name)
```

## Reading all events forward

This method allows us to load all stored events ascending.

This will read first 100 domain events stored in event store.

```ruby
client.read_all_streams_forward(start: :head, count: 100)
```

When not specified it reads events starting from `:head` (first domain event
stored in event store) and reads up to `RailsEventStore::PAGE_SIZE`
domain events.

```ruby
client.read_all_streams_forward
```

You could also read batch of domain events starting from any read or published event.

```ruby
client.read_all_streams_forward(start: last_read_event.event_id, count: 100)
```

## Reading all events backward

This method allows us to load all stored events descending.

This will read last 100 domain events stored in event store.
```ruby
client.read_all_streams_backward(start: :head, count: 100)
```

When not specified it reads events starting from `:head` (last domain event
stored in event store) and reads up to `RailsEventStore::PAGE_SIZE`
domain events.

```ruby
client.read_all_streams_backward
```
