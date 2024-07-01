---
title: Minitest assertions
---

## Installation

## Event assertions

### assert_dispatched(event_store, expected_events, &block)
Verifies that an event or events of certain type were published to the event store during the execution of the block.

Example usage:
```ruby
assert_dispatched(@event_store, DummyEvent) { @event_store.publish(DummyEvent.new) }

assert_dispatched(@event_store, [DummyEvent]) { @event_store.publish(DummyEvent.new) }
```

### assert_not_dispatched(event_store, expected_events, &block)
Verifies that an event or events of certain type were not published to the event store during the execution of the block.

```ruby
assert_not_dispatched(@event_store, [DummyEvent]) {}

assert_not_dispatched(@event_store, DummyEvent) {}
```

### assert_published(event_store, event_type, with_data: nil, with_metadata: nil, within_stream: nil, &block)
Verifies that an event of certain type was published to the event store.

```ruby
@event_store.publish(DummyEvent.new)
assert_published(@event_store, DummyEvent)

@event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
assert_published(@event_store, DummyEvent, with_data: { "foo" => "bar" })

@event_store.with_metadata(foo: "bar") { @event_store.publish(DummyEvent.new) }
assert_published(@event_store, DummyEvent, with_metadata: { "foo" => "bar" })
```

### assert_not_published(event_store, event_type, with_data: nil, with_metadata: nil, within_stream: nil, &block)
Verifies that an event of certain type was not published to the event store.

```ruby
@event_store.publish(DummyEvent.new)

assert_not_published(@event_store, AnotherDummyEvent)
```

### assert_published_once(event_store, event_type, with_data: nil, with_metadata: nil, within_stream: nil, &block)
Verifies that an event of certain type was published exactly once to the event store.

```ruby
@event_store.publish(DummyEvent.new)
@event_store.publish(AnotherDummyEvent.new)
assert_published_once(@event_store, DummyEvent)

assert_published_once(@event_store, DummyEvent) do
    @event_store.publish(DummyEvent.new)
end

@event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
assert_published_once(@event_store, DummyEvent, with_data: {foo: "bar"})

@event_store.with_metadata(foo: "bar") { @event_store.publish(DummyEvent.new) }
assert_published_once(@event_store, DummyEvent, with_metadata: { "foo" => "bar" })
```

### assert_nothing_published(event_store, &block)
Verifies that no events were published to the event store.

```ruby
assert_nothing_published(@event_store) {}
```

### assert_event_in_stream(event_store, event, stream_name)
Verify that an event is in given stream.

```ruby
event = DummyEvent.new
@event_store.publish(event, stream_name: "specific-stream")

assert_event_in_stream(@event_store, event, "specific-stream")
```

### assert_event_not_in_stream(event_store, event, stream_name)
Verify that an event doesn't exist in given stream.

```ruby
event = DummyEvent.new
@event_store.publish(event)

assert_event_not_in_stream(@event_store, event, "specific-stream")
```

### assert_exact_new_events(event_store, expected_new_events, &block)
Verify that all the new expected events were published to the event store.

```ruby
events = [DummyEvent.new, DummyEvent.new]
events.each { |event| @event_store.publish(event) }

new_events = [AnotherDummyEvent.new, AnotherDummyEvent.new]

assert_exact_new_events(@event_store, new_events.map(&:class)) do
new_events.each { |event| @event_store.publish(event) }
end
```

### assert_new_events_include(event_store, expected_events, &block)
Verify that the new expected events are inclued in the new events published to the event store.

```ruby
events = [DummyEvent.new, DummyEvent.new]
events.each { |event| @event_store.publish(event) }

new_events = [AnotherDummyEvent.new, AnotherDummyEvent.new, DummyEvent.new]

assert_new_events_include(@event_store, [DummyEvent]) do
new_events.each { |event| @event_store.publish(event) }
end
```

### assert_equal_event(expected_event, actual_event, verify_id = false)
Verify that two events are equal. If verify_id is true, the event ids are also verified.

```ruby
expected_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

@event_store.publish(DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" }))
actual_event = @event_store.read.backward.first

assert_equal_event(expected_event, actual_event)
assert_equal_event(expected_event, actual_event, verify_id: true) # fails, because ids are not equal

event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

@event_store.publish(event)
actual_event = @event_store.read.backward.first

assert_equal_event(event, actual_event, verify_id: true) # passes, because ids are equal
```

### assert_equal_events(expected_events, actual_events, verify_id = false)
Verify that two arrays of events are equal. If verify_id is true, the event ids are also verified.

```ruby
event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })
second_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

@event_store.publish(event)
@event_store.publish(second_event)
events = @event_store.read.backward.limit(2).to_a

assert_equal_events([event, second_event], events)
```
