---
title: Reading events
---

## Reading from stream

### Reading stream's events forward in batch — starting from first event

```ruby
stream_name = "order_1"
count = 40
client.read.stream(stream_name).from(:head).limit(count).each.to_a
```

In this case `:head` means first event of the stream.

### Reading stream's events forward in batch — starting from given event

```ruby
# last_read_event is any domain event read or published by rails_event_store

stream_name = "order_1"
start = last_read_event.event_id
count = 40
client.read.stream(stream_name).from(start).limit(count).each.to_a
```

### Reading stream's events backward in batch

As in examples above, just append `.backward` instead before `.each`.
In this case `:head` means last event of the stream.

```ruby
stream_name = "order_1"
start = last_read_event.event_id
count = 40
client.read.backward.stream(stream_name).from(start).limit(count).each.to_a
```

### Reading all events from stream forward

This method allows us to load all stream's events ascending.

```ruby
stream_name = "order_1"
client.read.stream(stream_name).each.to_a
```

### Reading all events from stream backward

This method allows us to load all stream's events descending.

```ruby
stream_name = "order_1"
client.read.backward.stream(stream_name).each.to_a
```

### Reading all events forward

This method allows us to load all stored events ascending.

This will read first 100 domain events stored in event store.

```ruby
client.read.from(:head).limit(100).each.to_a
```

When not specified it reads events starting from `:head` (first domain event
stored in event store) and without limit.

```ruby
client.read.each.to_a
```

You could also read batch of domain events starting from any read or published event.

```ruby
client.read.from(last_read_event.event_id).limit(100).each.to_a
```

### Reading all events backward

This method allows us to load all stored events descending.

This will read last 100 domain events stored in event store.

```ruby
client.read.backward.from(:head).limit(100).each.to_a
```

When not specified it reads events starting from `:head` (last domain event
stored in event store) and without limit.

```ruby
client.read.backward.each.to_a
```


## Reading specified events

RailsEventStore let's you read specific event (or a list of events).
You need to know ids of events you want to read.

Fetch a single event (will return a single domain event):

```ruby
client.read.event('some-event-id-here')
```

The `read.event` method will return `nil` if event cound not be found.
Use `read.event!` method to raise an `EventNotFound` error if event cound not be found.


Fetch a multiple events at once (will return an array of domain events):

```ruby
client.read.events(['event-1-id', 'event-2-id', ... 'event-N-id'])
```

The `read.events` method will return only existing events. If none of given ids
could not be found it will return empty collection.
