---
title: Reading events
---

## Specifying read scope

You could use a specification pattern to prepare a read scope.
The read scope defines what domain events will be read.

The available specification methods are:

* `stream(stream_name)` - specify the name of a stream to read.
   If no stream is specified, a global stream (all domain events)
   will be read.
* `from(start)` - specify the starting point (event id) for read operation. 
   This will read all domain events after (but not including) the specified domain event id.
* `to(stop)` - specify the stop point (event id) for the read operation. This will
   read all domain events up until (but not including) the specified domain event id.
* `forward` - reading direction, from oldest to newest domain events.
* `backward` - reading direction, from newest to oldest  domain events.
* `limit(count)` - maximum number of events to read.
* `in_batches(batch_size)` - read will be performed in batches of the specified size.
   RailsEventStore never reads all domain events at once. Even if you don't specify
   a batch size, the read operation will be performed in batches of 100.
* `of_type(types)` - read only specified types of domain events, ignoring all others.

The read scope could be defined by chaining the specification methods, e.g.:

```ruby
scope = client.read
  .stream('GoldCustomers')
  .backward
  .limit(100)
  .of_type([Customer::GoldStatusGranted])
```

When the read scope is defined, several methods can be used to get the data:

* `count` - returns total number of domain events to be read.
* `each` - returns an enumerator for all domain events in the read scope.
* `each_batch` - returns an enumerator of batches of specified size (or 100 if no
   batch size has been specified).
* `to_a` - returns an array with all domain events from the scope, equal to `each.to_a`.
* `first` - returns the first domain event from the read scope.
* `last` - returns the last domain event from the read scope.
* `event(event_id)` - return an event of a given id if found in the read scope, otherwise `nil`.
* `event!(event_id)` - return an event of a given id if found in the read scope,
   otherwise raises `RubyEventStore::EventNotfound` error.
* `events(event_ids)` - returns a list of domain events of given ids found in the read scope.
   If there is no event for one or more provided event id, that id will be ignored (not all domain events must be found).

## Examples

### Reading a stream's events forward — starting from the first event

```ruby
stream_name = "order_1"
count = 40
client.read.stream(stream_name).limit(count).to_a
```

### Reading a stream's events forward — starting from a given event

```ruby
# last_read_event is any domain event read or published by rails_event_store

stream_name = "order_1"
start = last_read_event.event_id
count = 40
client.read.stream(stream_name).from(start).limit(count).to_a
```

### Reading a stream's events backward

As in examples above, just append `.backward` before `.each`.

```ruby
stream_name = "order_1"
start = last_read_event.event_id
count = 40
client.read.backward.stream(stream_name).from(start).limit(count).to_a
```

### Reading all events from a stream forward

This method allows us to load all of a stream's events in ascending order.

```ruby
stream_name = "order_1"
client.read.stream(stream_name).to_a
```

### Reading all events from a stream backward

This method allows us to load all of a stream's events in descending order.

```ruby
stream_name = "order_1"
client.read.backward.stream(stream_name).to_a
```

### Reading all events forward

This method allows us to load all stored events in ascending order.

This will read first 100 domain events stored in the event store.

```ruby
client.read.limit(100).to_a
```

When not specified, it reads events starting from the first domain event
stored in the event store, with no limit applied.

```ruby
client.read.to_a
```

You can also read batch of domain events starting from any read or published event.

```ruby
client.read.from(last_read_event.event_id).limit(100).to_a
```

### Reading all events backward

This method allows us to load all stored events in descending order.

This will read last 100 domain events stored in the event store.

```ruby
client.read.backward.limit(100).to_a
```

When not specified, it reads events starting from the last domain event
stored in event store, with no limit applied.

```ruby
client.read.backward.to_a
```

### Reading events using batches explicitly

```ruby
client.read.in_batches.each do |event|
  # do something with event
end
```

### Reading events and iterating over each batch

```ruby
client.read.in_batches.each_batch do |batch|
  # do something with given batch of events of default size
end
```

### Reading events using batches of custom size and iterating over each batch

```ruby
client.read.in_batches(42).each_batch do |batch|
  # do something with batch of events of size 42
end
```

## Reading specific events

RailsEventStore lets you read a specific event (or a list of events).
You need to know the ids of events you want to read.

Fetch a single event (will return a single domain event):

```ruby
client.read.event('some-event-id-here')
```

The `read.event` method will return `nil` if the event cannot be found.
Use `read.event!` method to raise an `EventNotFound` error if the event cannot be found.


Fetch multiple events at once (will return an array of domain events):

```ruby
client.read.events(['event-1-id', 'event-2-id', ... 'event-N-id'])
```

The `read.events` method will return only existing events. If none of given ids
can be found, it will return an empty collection.
