---
title: CLI
---

The `res` command-line interface lets you inspect your event store directly from the terminal — without opening a Rails console, writing SQL, or adding custom rake tasks. It is a quick way to browse streams and events while developing or debugging.

It is the terminal counterpart to the [Browser](./browser/): where the Browser gives you a web interface, the CLI answers the same questions ("What happened in this stream?", "Was this event persisted?", "What does the latest event look like?") from your shell.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ruby_event_store-cli"
```

Run all commands from your application's root directory. The CLI autodetects `config/environment.rb` and loads your Rails environment, so it connects to the same `Rails.configuration.event_store` your application uses.

Every command goes through the public `event_store` API — no SQL, no adapter internals — so it works regardless of the storage adapter underneath.

## Streams

### `stream show`

Event count, current version, and the first and last event of a stream:

```
$ bundle exec res stream show 'Order$f47ac10b-58cc-4372-a567-0e02b2c3d479'
Stream:  Order$f47ac10b-58cc-4372-a567-0e02b2c3d479
Events:  2
Version: 1
First:   2026-03-24T17:45:03.891Z (OrderPlaced)
Last:    2026-03-24T17:46:12.004Z (OrderConfirmed)
```

### `stream events`

By default it prints the stream as a table:

```
$ bundle exec res stream events Order$<order_id>
EVENT ID                              TYPE                                      TIMESTAMP
------------------------------------------------------------------------------------------
59588873-00fa-423f-89d1-03d7c3b0ab35  OrderPlaced                               2026-03-24T17:45:03.891Z
6f1c2d3e-4a5b-4c6d-8e9f-0a1b2c3d4e5f  OrderConfirmed                            2026-03-24T17:46:12.004Z

2 event(s)
```

The filters combine freely:

```bash
# Filter by event type
bundle exec res stream events Order$<order_id> --type OrderPlaced

# Newer than a timestamp (ISO8601)
bundle exec res stream events Order$<order_id> --after 2026-03-01T00:00:00Z

# Older than a timestamp
bundle exec res stream events Order$<order_id> --before 2026-04-01T00:00:00Z

# Cap the number of events (default: 50)
bundle exec res stream events Order$<order_id> --limit 10

# Paginate — start after a known event ID
bundle exec res stream events Order$<order_id> --from 3fa85f64-5717-4562-b3fc-2c963f66afa6
```

Add `--follow` (or `-f`) to keep the command running and print new events in this stream as they arrive — a live tail of a single stream:

```bash
bundle exec res stream events Order$<order_id> --follow
```

## Events

### `event show`

Full detail for a single event ID, data and metadata included:

```
$ bundle exec res event show 59588873-00fa-423f-89d1-03d7c3b0ab35
Event ID:   59588873-00fa-423f-89d1-03d7c3b0ab35
Type:       OrderPlaced
Timestamp:  2026-03-24T17:45:03.891Z
Valid at:   2026-03-24T17:45:03.891Z
Data:       {
  "order_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "customer_id": "c-1024",
  "total": "149.00"
}
Metadata:   {
  "correlation_id": "452fd6f0-e3a2-4716-bc8a-43bbcf2cae61",
  "causation_id": "452fd6f0-e3a2-4716-bc8a-43bbcf2cae61"
}
```

### `event streams`

An event is published to one stream and can be [linked](./link/) into many. This lists every stream it belongs to:

```
$ bundle exec res event streams 59588873-00fa-423f-89d1-03d7c3b0ab35
Order$f47ac10b-58cc-4372-a567-0e02b2c3d479
$by_type_OrderPlaced
$by_correlation_id_452fd6f0-e3a2-4716-bc8a-43bbcf2cae61
```

## Search across the store

### `search`

While `stream events` is scoped to one stream, `search` looks across the whole store. It takes the same filters — `--type`, `--after`, `--before`, `--limit` — plus `--stream` to scope back down when you want to:

```
$ bundle exec res search --type OrderPlaced --after 2026-03-01T00:00:00Z
EVENT ID                              TYPE                                      TIMESTAMP
------------------------------------------------------------------------------------------
59588873-00fa-423f-89d1-03d7c3b0ab35  OrderPlaced                               2026-03-24T17:45:03.891Z
8b1f2c3d-1a2b-4c3d-9e8f-7a6b5c4d3e2f  OrderPlaced                               2026-03-22T09:13:55.620Z

2 event(s)
```

### `stats`

Total event count and the unique event types present — across the store, or for one stream with `--stream`:

```
$ bundle exec res stats
Events:  1432

Event types:
  OrderCancelled
  OrderConfirmed
  OrderPlaced
  PaymentAuthorized
  ShipmentScheduled
```

```
$ bundle exec res stats --stream Order$<order_id>
Stream:  Order$f47ac10b-58cc-4372-a567-0e02b2c3d479
Events:  2

Event types:
  OrderConfirmed
  OrderPlaced
```

## JSON output

`stream events` and `search` can both emit JSON instead of a table with `--format json`. That makes them easy to combine with tools like [`jq`](https://jqlang.github.io/jq/) or to pipe into your own scripts:

```bash
# What data did our last OrderPlaced carry?
bundle exec res stream events Order$<order_id> \
  --type OrderPlaced \
  --limit 1 \
  --format json \
  | jq '.[0].data'

# Any events with missing customer_id?
bundle exec res search --type OrderPlaced --format json \
  | jq '.[] | select(.data.customer_id == null)'

# Unique event types in a stream
bundle exec res stream events Order$<order_id> --format json \
  | jq '[.[].event_type] | unique'
```

Each JSON event carries `event_id`, `event_type`, `data`, `metadata`, and `timestamp`.

## Trace correlated events

Give `res trace` a [correlation ID](./correlation-causation/) and it gathers every event sharing it, then shapes them by causation — which event triggered which — into a tree:

```
$ bundle exec res trace 452fd6f0-e3a2-4716-bc8a-43bbcf2cae61
OrderPlaced [452fd6f0-e3a2-4716-bc8a-43bbcf2cae61]
├── PaymentAuthorized [7c9e6679-7425-40de-944b-e07fc1f90ae7]
│   └── OrderConfirmed [a1b2c3d4-5e6f-4a8b-9c0d-1e2f3a4b5c6d]
└── ShipmentScheduled [9f8e7d6c-5b4a-4938-8271-6f5e4d3c2b1a]
```

The tree makes it obvious where a workflow stopped. If a branch is missing, you immediately know which handler never published its follow-up event — without digging through logs.

`trace` relies on correlation linking. As related events are published, Rails Event Store links them into a `$by_correlation_id_...` stream while preserving correlation and causation IDs. The command reconstructs the tree from those links.

## Watch events live

`res watch` gives you a live view of everything happening in the event store, grouped by bounded-context namespace (the part before `::` in the event type). It is handy during demos, load tests, or while reproducing a multi-step flow:

```
$ bundle exec res watch
Fulfillment (2 events)
  OrderPlaced                     17:45:03  452fd6f0-e3a2-4716-bc8a-43bbcf2cae61
  OrderConfirmed                  17:45:04  a1b2c3d4-5e6f-4a8b-9c0d-1e2f3a4b5c6d

Payments (1 events)
  PaymentAuthorized               17:45:03  7c9e6679-7425-40de-944b-e07fc1f90ae7

Watching since 17:45:00 — Press Ctrl+C to exit
```

The display updates in place instead of scrolling. A few flags control what it shows and how often:

- `--namespace Fulfillment,Payments` — only show those namespaces
- `--since 2026-03-24T17:00:00Z` — start from a timestamp instead of "now"
- `--limit 50` — max events shown per namespace (default: 50)
- `--interval 1` — refresh interval in seconds (default: 1)

Where `stream events --follow` tails one stream, `watch` gives you the whole store at a glance.

## Command reference

| Command | What it does |
|---|---|
| `stream show` | Event count, version, and first/last event of a stream |
| `stream events` | Read a stream's events, with filtering, pagination, and `--follow` |
| `event show` | Full detail of one event — data, metadata, timestamps |
| `event streams` | Every stream an event is published or linked to |
| `search` | Find events across all streams by type, time, or stream |
| `stats` | Total count and unique event types, store-wide or per stream |
| `trace` | Causation tree for everything sharing a correlation ID |
| `watch` | Live feed of new events, grouped by namespace |
