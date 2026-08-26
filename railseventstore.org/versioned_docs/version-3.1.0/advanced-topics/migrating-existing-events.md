---
title: Migrating existing events
---

There are two strategies for evolving events over time: **upcasting** (transform on read, leave storage unchanged) and **permanent migration** (rewrite stored events).
Choose upcasting when you want a non-destructive, incremental approach; choose permanent migration when you want a clean slate and are ready to rewrite history.

## Upcasting

Upcasting transforms events at read time without touching stored data. The mapper applies your upcast functions every time an event is loaded from the event store,
converting older representations to the current shape on the fly.

This is useful when:

- You are renaming an event class and want old records to be read as the new class
- You are evolving the data shape of an event and want to express that as a versioned chain

### Setup

Add `RubyEventStore::Mappers::Transformation::Upcast` to your mapper pipeline and provide an upcast map — a hash keyed by `event_type` string,
where each value is a callable that receives a `RubyEventStore::Record` and returns a transformed `Record`:

```ruby
upcast_map = {
  "OrderPlaced" => lambda do |record|
    RubyEventStore::Record.new(
      event_id:   record.event_id,
      metadata:   record.metadata,
      timestamp:  record.timestamp,
      valid_at:   record.valid_at,
      event_type: record.event_type,
      data:       record.data.merge(currency: "USD"),
    )
  end
}

class MyMapper < RubyEventStore::Mappers::PipelineMapper
  def initialize(upcast_map)
    super(RubyEventStore::Mappers::Pipeline.new(
      RubyEventStore::Mappers::Transformation::Upcast.new(upcast_map),
      RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
    ))
  end
end

Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new(
      mapper: MyMapper.new(upcast_map)
    )
  end
end
```

### Chaining upcasts

When an upcast changes the `event_type`, the engine automatically applies the next matching upcast, following the chain until no further entry exists in the upcast map.
This lets you express multi-step migrations incrementally:

```ruby
upcast_map = {
  # v1 → v2: rename type, convert data format
  "OrderPlaced_v1" => lambda do |record|
    RubyEventStore::Record.new(
      event_id:   record.event_id,
      metadata:   record.metadata,
      timestamp:  record.timestamp,
      valid_at:   record.valid_at,
      event_type: "OrderPlaced_v2",
      data:       { order_id: record.data[:id], amount: record.data[:total] },
    )
  end,

  # v2 → v3: add currency field
  "OrderPlaced_v2" => lambda do |record|
    RubyEventStore::Record.new(
      event_id:   record.event_id,
      metadata:   record.metadata,
      timestamp:  record.timestamp,
      valid_at:   record.valid_at,
      event_type: "OrderPlaced_v3",
      data:       record.data.merge(currency: "USD"),
    )
  end
}
```

A record stored as `OrderPlaced_v1` will be transformed through `v1 → v2 → v3` automatically on each read.

Each upcast **must** change the `event_type`. Returning a record with the same `event_type` raises `RubyEventStore::InvalidUpcast`.

## Permanent migration

Permanent migration rewrites stored events in place. There are significant trade-offs — you are rewriting history — so make sure you [understand them well](https://leanpub.com/esversioning/read#leanpub-auto-immutability) before going this route. Prefer upcasting when possible.
