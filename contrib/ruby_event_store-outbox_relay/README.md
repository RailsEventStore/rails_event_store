# Ruby Event Store — Outbox Relay

Transactional outbox for Rails Event Store, built on a single `published_at` column on `event_store_events` instead of a separate outbox table.

Every published event is persisted with `published_at` left `NULL`, in the same INSERT that writes the event. A separate, independent process (the **relay**) picks up unpublished events in batches and marks them published once dispatched. The write and the "intent to deliver" happen in the same SQL transaction, so a crash between saving an event and notifying subscribers can no longer lose the notification.

Delivery is decided **per subscriber**, not per event:

- **`subscribe_sync`** (identical to the original `subscribe`, kept as a working alias) — the handler is called synchronously, in-process, exactly as it always has been.
- **`subscribe_async`** — the handler is delivered exclusively by the relay, by default through ActiveJob.

`publish` itself is unchanged: it still dispatches to every sync subscriber for every event, immediately. The two subscription kinds are disjoint sets of handlers, so nothing is ever delivered twice.

## Why not the existing `ruby_event_store-outbox` gem?

`ruby_event_store-outbox` transactionally enqueues background jobs (Sidekiq) into a dedicated outbox table. This gem is a different, more direct shape: no second table to keep in sync, no background-job format of its own — it's a raw column on your existing events table, and the relay calls a broker directly, the same way a synchronous `publish` would. Use whichever shape fits your infrastructure; they solve overlapping but distinct problems and can coexist.

## Design: zero changes to `ruby_event_store`

None of this is built into `ruby_event_store` or `ruby_event_store-active_record` — this gem extends those classes at runtime instead, via `Module#prepend`, the same mechanism `ruby_event_store` itself uses internally for deprecation wrappers. Nothing in either core gem is modified; the extension is entirely contained here and disappears cleanly if you remove the gem.

Both extensions are applied at gem-load time, side by side, in `lib/ruby_event_store/outbox_relay.rb` — not scattered across the extension files, so the two stay in lockstep: `ClientExtension` is included onto `RubyEventStore::Client` (extending every client, including subclasses like `RailsEventStore::Client`), and `EventRepositoryExtension` is prepended onto `RubyEventStore::ActiveRecord::EventRepository`, writing every event with `published_at: NULL` unconditionally. There's no opt-in step and no toggle: requiring this gem without eventually running a relay leaves every event written from then on permanently `published_at: NULL`.

## Requirements

- Ruby >= 3.3
- `ruby_event_store` >= 3.0.0, `ruby_event_store-active_record` >= 3.0.0, `rails_event_store` >= 3.0.0
- PostgreSQL (any supported version) or MySQL >= 8.0 (relay concurrency relies on `SKIP LOCKED`, available since MySQL 8.0)

## Installation (app)

Add to your Gemfile:

```ruby
gem "ruby_event_store-outbox_relay"
```

Generate and run the migration adding `published_at` to `event_store_events`:

```
bundle exec rake ruby_event_store:outbox_relay:install_migration
bin/rails db:migrate
```

The migration backfills existing rows so they count as already published — the relay will never try to (re-)send your event history on first deploy.

Requiring the gem is all it takes — no opt-in call. `ruby_event_store/outbox_relay.rb` includes `ClientExtension` onto `RubyEventStore::Client` and prepends `EventRepositoryExtension` onto `RubyEventStore::ActiveRecord::EventRepository` in one place, side by side, so the client and the repository are always extended together (this also covers Rails apps, where the repository is wrapped in `RubyEventStore::InstrumentedRepository`, since `InstrumentedRepository` just forwards `append_to_stream` through unmodified). Every `RubyEventStore::Client` (and subclass, including `RailsEventStore::Client`) gains two new subscription methods and a public `async_broker`:

```ruby
event_store = RailsEventStore::Client.new

# Delivered synchronously, in-process -- unchanged behavior, `subscribe` still works too.
event_store.subscribe_sync(OrderMailer, to: [OrderPlaced])

# Delivered exclusively by the relay. OrderReportJob must be an ActiveJob class
# (the default async_broker dispatches through RailsEventStore::ActiveJobScheduler).
event_store.subscribe_async(OrderReportJob, to: [OrderPlaced])

event_store.publish(OrderPlaced.new(data: { order_id: order.id }))
# OrderMailer runs immediately. OrderReportJob only runs once the relay processes
# this event -- see "Installation (relay process)" below.
```

Unlike `subscribe_sync`, `subscribe_async` takes no block — the subscriber must be a named, resolvable class. A block is an anonymous `Proc`, which can't be serialized for ActiveJob (or any other asynchronous processor), so passing one is a mistake the signature rules out up front.

`async_broker` defaults to `RubyEventStore::ImmediateDispatcher` scheduling through `RailsEventStore::ActiveJobScheduler`, reusing the repository's own serializer. Pass a different one at construction time if you need something else -- this works on `RailsEventStore::Client` and on plain `RubyEventStore::Client` alike:

```ruby
RailsEventStore::Client.new(async_broker: RubyEventStore::Broker.new(dispatcher: MyOwnDispatcher.new))
```

## Installation (relay process)

The relay reads its broker, mapper, and serializer straight from your application's `Client` — pass the client itself, built from a file you point the process at with `--require`.

```ruby
# config/outbox_relay.rb
require "ruby_event_store/outbox_relay"

RubyEventStore::OutboxRelay::Configuration.configure do |batch_size:, poll_interval:, logger:|
  client = RailsEventStore::Client.new
  client.subscribe_async(OrderReportJob, to: [OrderPlaced])

  RubyEventStore::OutboxRelay::Relay.new(
    client: client,
    batch_size: batch_size,
    poll_interval: poll_interval,
    logger: logger,
  )
end
```

The relay's `client` only needs its `subscribe_async` registrations to matter — synchronous subscribers registered on it are never triggered by the relay (`process_batch` only ever calls `client.async_broker`).

Run it:

```
bundle exec res_outbox_relay --require=config/outbox_relay.rb --database-url="$DATABASE_URL"
```

Run it as many instances as you like — `FOR UPDATE SKIP LOCKED` means concurrent relays never process the same batch twice. A systemd unit template (`Restart=always`) is included at `support/systemd/res-outbox-relay.service`; a `bundle exec rake ruby_event_store:outbox_relay:run` task is also available for environments that prefer rake.

### Options

| Option              | Required | Default | Description                                                         |
| ------------------- | -------- | ------- | --------------------------------------------------------------------|
| `--require`          | yes      | —       | Ruby file calling `Configuration.configure` to build the relay      |
| `--database-url`      | no       | —       | Database where `event_store_events` is stored                       |
| `--batch-size`        | no       | 100     | Number of events fetched per batch                                  |
| `--poll-interval`     | no       | 1.0     | Seconds to sleep after an empty batch                               |
| `--log-level`         | no       | info    | One of: `fatal`, `error`, `warn`, `info`, `debug`                   |

## Guarantees

- **At-least-once delivery for async subscribers.** If dispatching a batch raises, the whole transaction rolls back — `published_at` stays `NULL` and the event is retried on the next pass. Your async subscribers must be idempotent by `event_id`.
- **Exactly-once dispatch per subscriber.** Sync and async subscribers are disjoint sets registered on two different brokers — a handler is either called by `publish` or by the relay, never both.
- **No duplicated work across relay instances**, via `SELECT ... FOR UPDATE SKIP LOCKED`.
- **Same metadata context as a synchronous publish** — `correlation_id`/`causation_id` are reproduced through `with_metadata` exactly as `Client#publish` does it.

See the [full documentation](https://railseventstore.org/docs/advanced-topics/outbox-relay) for the underlying design and more examples.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RailsEventStore/rails_event_store.

## Releasing

1. Bump version
2. `make build`
3. `make push`
