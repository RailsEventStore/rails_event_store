---
title: Publishing unique events
---

You can take advantage of the [Expected Version](../core-concepts/expected-version/) feature to ensure retry-safety when publishing events that should be published only once.
E.g. when you receive an external system payload and store it as an event for further processing. You want to publish the event once, even if it is delivered multiple times for any reason.

A simple pattern is to call publish for a stream whose name is built of idempotency key and expect that stream to be empty, at the time of publishing, by passing `expected_version: none`.

### Example implementation

```ruby
def publish_event_uniquely(event, *fields)
  uniqueness_key = [event.event_type, *fields].join("_")
  event_store.publish(event, stream_name: "$unique_by_#{uniqueness_key}", expected_version: :none)
rescue RubyEventStore::WrongExpectedEventVersion
end
```

`RubyEventStore::WrongExpectedEventVersion` raises when the stream with this name isn't empty. It means that for a given idempotency key, an event has been already published. We safely ignore this error.

### Building uniqueness key
If you don't have a real idempotency key, you can try to build one from the event type and some reasonably selected values.
Be careful what you put in there! Ensure that the values you use stay the same for the repeated intent but differ for another one.