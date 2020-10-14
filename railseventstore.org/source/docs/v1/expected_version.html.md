---
title: Expected Version explained
---

There are 3 values that you can use for providing `expected_version` when publishing an event in a stream: `:any`, an Integer, `:auto`.

## :any

```ruby
event_store.publish(
  event,
  stream_name: "Order-1",
  expected_version: :any,
)
```

#### Guarantees

- When there are many threads (or processes) writing concurrently (at the same time) to a stream with `expected_version` set to `:any`, all of those writes should succeed.
  - When you later try to read those events you from a stream, you don't have a guarantee about particular order you are going to get them in.
  - Example: If 3 processes A,B,C publish events to stream `foo-1` at the same time, all of them should succeed. When you read events from stream `foo-1` you will get events A,B,C or A,C,B or B,A,C or B,C,A or C,A,B or C,B,A.
- Should never fail
- When a single thread (or process) writes events A, B to a stream, it is guaranteed you will retrieve events A,B in that exact order when reading from a stream.

#### Usage

- This is a default value in RES when `expected_version` is not provided
- Good for technical streams
- Good if you use RES as pub-sub and only sometimes you read the events for debugging purposes
- Good if exact order events is not critical

## explicit number (Integer, from -1..∞)

You start by publishing the first event in a stream with `expected_version` being `-1` (or `:none`). That means you expect no events in the stream right now.

```ruby
event_store.publish(
  event0,
  stream_name: "Order-1",
  expected_version: -1,   # or :none which is a synonym
                          # for -1
)
```

The first published event is at position `0`. When you publish a second event you provide `expected_version: 0`.

```ruby
event_store.publish(
  [event1, event2],
  stream_name: "Order-1",
  expected_version: 0,
)
```

We published the second and third events. Their positions are `1` and `2`. That's why when you publish the next event you need to provide `expected_version: 2`.

```ruby
event_store.publish(
  event3,
  stream_name: "Order-1",
  expected_version: 2,
)
```

In other words when you say `expected_version: 2` that means: _When I publish those events I expect the last event in the stream to be exactly at the position `2`._ So you expect exactly 3 events to be in that stream at positions `0, 1, 2`. Not less, not more.

If the `expected_version` does not match and another thread (or process) wrote different events in the meantime your write will fail with `RubyEventStore::WrongExpectedEventVersion` exception. This exception is thrown before any handlers are invoked.

This mode effectively acts as optimistic locking.

#### Guarantees

- When there are many threads (or processes) writing concurrently (at the same time) to a stream with `expected_version` set to the same correct number, only one of those writes will succeed.
- When a single thread (or process) writes events A, B to a stream, it is guaranteed you will retrieve events A,B in that exact order when reading from a stream.
- Succeeds when there were no other successful concurrent writes, raises `RubyEventStore::WrongExpectedEventVersion` otherwise (also aliased as `RailsEventStore::WrongExpectedEventVersion`).

#### Usage

- good for Event Sourcing
  - this is what [`aggregate_root` gem is using](https://github.com/RailsEventStore/rails_event_store/blob/d23640e4bcd54ac2e0f8af60c1ff8633632c0d99/aggregate_root/lib/aggregate_root.rb#L26)
- good if you need deterministic, exact order of events in a stream even when there are multiple, concurrent events being published.

## :auto

```ruby
event_store.publish(
  event,
  stream_name: "Order-1",
  expected_version: :auto,
)
```

`:auto` is like explicitly providing the number for `expected_version` but RES will automatically find the position of last event in a stream.

There is a potential for a race condition between reading the `expected_version` and providing it for a write. That's why this mode only makes sense if you always use your custom, application specific locking mechanism around (using mutexes or custom DB locks).

```ruby
application_lock("Order-1") do
  # do something with Order 1...
  event_store.publish(
    event,
    stream_name: "Order-1",
    expected_version: :auto,
  )
end
```

The guarantees mentioned below **assume there is no application specific lock.**

#### Guarantees

- When there are many threads (or processes) writing concurrently (at the same time) to a stream with `expected_version` set to the same correct number, at least one of those writes will succeed.
- When a single thread (or process) writes events A, B to a stream, it is guaranteed you will retrieve events A,B in that exact order when reading from a stream.
- Succeeds when there were no other successful concurrent writes, raises `RubyEventStore::WrongExpectedEventVersion` otherwise (also aliased as `RailsEventStore::WrongExpectedEventVersion`).

#### Usage

- good if you need deterministic, exact order of events in a stream even when there are multiple, concurrent events being published. But you already have a custom layer of locks which prevents potential concurrency issues.

## Beware

- You should never mix `expected_version: :any` with `:auto` or explicit number (`Integer`) for the same stream name.
- These described semantics are valid since `v0.19` and for `rails_event_store_active_record` adapter (which has always been the default).
