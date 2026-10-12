# Ruby Event Store — Outbox Relay

Transactional outbox for Rails Event Store, built on two small tables next to `event_store_events`. The events table is never altered.

`publish` writes the event and, in the same SQL transaction, one **outbox message** per async subscriber of that event. A separate, independent process (the **relay**) claims due messages in short transactions, delivers them with no transaction open, and deletes them once delivered. The write and the "intent to deliver" are atomic, so a crash between saving an event and notifying subscribers can no longer lose the notification.

Delivery is decided **per subscriber**, not per event:

- **`subscribe_sync`** (identical to the original `subscribe`, kept as a working alias) — the handler is called synchronously, in-process, exactly as it always has been.
- **`subscribe_async`** — the handler is delivered exclusively by the relay, by default through ActiveJob.

`publish` still dispatches to every sync subscriber immediately, after the transaction commits. The two kinds are disjoint sets of handlers, so nothing is ever delivered twice by the two paths. Event types without async subscribers write no outbox messages at all.

## Why not the existing `ruby_event_store-outbox` gem?

`ruby_event_store-outbox` transactionally enqueues background jobs (Sidekiq) into a dedicated outbox table. This gem calls a broker-shaped dispatcher directly, the same way a synchronous `publish` would, and keeps per-subscriber retry state and a dead letter table instead of a job format of its own. Use whichever shape fits your infrastructure; they solve overlapping but distinct problems and can coexist.

## Design

```
publish ──▶ [ BEGIN; INSERT event(s); INSERT outbox message per (event, async subscriber); COMMIT ] ──▶ sync subscribers

relay:  claim ──▶ dispatch (no transaction) ──▶ delete delivered
         │                    │
         │ lease              ├─ failed ──▶ retry later (backoff)
         ▼                    └─ gave up ──▶ dead letters
   next_attempt_at
```

- **`event_store_outbox_messages`** — one row per (event, subscriber): `event_id`, `topic`, `subscriber` (the handler's class name), `attempts`, `next_attempt_at`, `last_error`. It only ever holds work still to do, so it stays small.
- **`event_store_outbox_dead_letters`** — deliveries that exhausted their attempts or failed with a permanent error, with the error class, message and backtrace. See [Dead letters](https://railseventstore.org/docs/advanced-topics/outbox-relay#dead-letters).
- The relay claims messages with `FOR UPDATE SKIP LOCKED` in a transaction that only moves `next_attempt_at` to the end of a **lease** (five minutes by default). Other relays skip leased messages, and a relay that crashes mid-batch releases its messages simply by the lease running out.
- The relay reads the event from `event_store_events` by id when it delivers; the outbox never duplicates event data.
- **No monkeypatching, no ambient state.** The outbox client is a subclass of `RubyEventStore::Client` (or `RailsEventStore::Client`) that overrides `publish`; requiring this gem changes no existing class, and the event repository is not touched at all. `append` is not overridden and, as documented, notifies no one, so it writes no messages.

## Requirements

- Ruby >= 3.3
- `ruby_event_store` and `ruby_event_store-active_record` >= 3.0.0 and < 4: the outbox client's `publish` repeats the steps of `RubyEventStore::Client#publish`, and relies on its internals, hence the pin
- `activerecord` and `activejob` >= 7.1
- `rails_event_store` >= 3.0.0, only for `RailsClient`
- PostgreSQL (any supported version) or MySQL >= 8.0 (relay concurrency relies on `SKIP LOCKED`, available since MySQL 8.0). SQLite works for a single relay instance only: it has no row locks.

## Installation (app)

Add to your Gemfile:

```ruby
gem "ruby_event_store-outbox_relay"
```

In a Rails application, load the Rails integration too, which defines `RailsClient` and needs `rails_event_store`:

```ruby
gem "ruby_event_store-outbox_relay", require: "ruby_event_store/outbox_relay/rails"
```

Generate and run the migration creating the outbox tables:

```
bundle exec rake ruby_event_store:outbox_relay:install_migration
bin/rails db:migrate
```

Requiring the gem changes nothing by itself. You opt in by building your client from `RubyEventStore::OutboxRelay::Client` (a `RubyEventStore::Client`) or, in Rails, `RubyEventStore::OutboxRelay::RailsClient` (a `RailsEventStore::Client`), which take the same arguments as the classes they extend. Both gain `subscribe_sync`, `subscribe_async`, `async_subscriptions` and `outbox`:

```ruby
event_store = RubyEventStore::OutboxRelay::RailsClient.new

event_store.subscribe_sync(OrderMailer, to: [OrderPlaced])
event_store.subscribe_async(OrderReportJob, to: [OrderPlaced])

event_store.publish(OrderPlaced.new(data: { order_id: order.id }))
# OrderMailer runs immediately. OrderReportJob only runs once the relay delivers the message.
```

To extend a client class of your own instead, include the module into a subclass of a client: `class EventStoreClient < RailsEventStore::Client; include RubyEventStore::OutboxRelay::ClientExtension; end`.

The application uses the registered subscribers to decide which messages to write; the relay uses them to resolve a message's `subscriber` name back to a handler. It resolves names only through this registry — never by constant lookup — so a row in the outbox table can only ever reach a handler you registered. A message naming an unregistered subscriber is retried, and dead-lettered once the retry policy gives up. Run the relay with the very client of your application (see below), so the list of async subscribers is defined once.

The subscriber must be a named class: its name is what the outbox stores. Unlike `subscribe_sync`, `subscribe_async` takes no block.

`async_subscriptions` defaults to `RubyEventStore::OutboxRelay::ActiveJobDispatcher` with the YAML serializer, so handlers must be ActiveJob classes; the relay enqueues each batch of jobs at once, see [Throughput](https://railseventstore.org/docs/advanced-topics/outbox-relay#throughput). Pass a different one at construction time:

```ruby
dispatcher = RubyEventStore::ImmediateDispatcher.new(scheduler: MyScheduler.new)
RubyEventStore::OutboxRelay::RailsClient.new(
  async_subscriptions: RubyEventStore::OutboxRelay::AsyncSubscriptions.new(dispatcher: dispatcher),
)
```

The outbox is written in the very transaction of the events, which holds only when the outbox tables are reached through the same connection as the event store. The outbox models inherit from `ActiveRecord::Base`, so that is the case when the event store does too. If the event store lives on another connection, say through an abstract base class of its own, give the client an outbox built on models that inherit from that class, and the same to the dead letter tasks:

```ruby
class OutboxMessage < EventStoreRecord; self.table_name = "event_store_outbox_messages"; end
class OutboxDeadLetter < EventStoreRecord; self.table_name = "event_store_outbox_dead_letters"; end

outbox = RubyEventStore::OutboxRelay::Outbox.new(message_klass: OutboxMessage, dead_letter_klass: OutboxDeadLetter)
client = RubyEventStore::OutboxRelay::RailsClient.new(repository: repository, outbox: outbox)
RubyEventStore::OutboxRelay::DeadLetters.new(message_klass: OutboxMessage, dead_letter_klass: OutboxDeadLetter)
```

`publish(event, topic: "custom")` writes messages for the async subscribers of that topic, exactly as it notifies the sync subscribers of that topic.

## Installation (relay process)

The relay reads its subscriptions, outbox and mapper straight from a `Client` — the one of your application, so `subscribe_async` is called in one place only. Point the process at a file that loads the application and builds the relay, with `--require`:

```ruby
# config/outbox_relay.rb
require_relative "environment"

RubyEventStore::OutboxRelay::Configuration.configure do |**options|
  RubyEventStore::OutboxRelay::Relay.new(client: Rails.configuration.event_store, **options)
end
```

The block receives the options given on the command line as keywords, `logger` always among them, and passes them on to `Relay.new`. A block that can't take one of them makes the relay fail at startup, naming it, instead of running with a batch size that was not the one asked for.

Synchronous subscribers of the client are never triggered by the relay. The relay refuses a client that isn't an outbox client, and at startup it logs the async subscribers of every topic, warning when there are none — in which case every message would fail, and be dead-lettered in the end.

Run it:

```
DATABASE_URL="postgres://relay@db/app" bundle exec res_outbox_relay --require=config/outbox_relay.rb
```

Run it as many instances as you like — `FOR UPDATE SKIP LOCKED` plus leases mean concurrent relays never claim the same message. A systemd unit template (`Restart=always`) is included at `support/systemd/res-outbox-relay.service`; a `bundle exec rake ruby_event_store:outbox_relay:run` task is also available for environments that prefer rake.

### `Relay` options

| Option            | Default              | Description                                                                                          |
| ----------------- | -------------------- | ---------------------------------------------------------------------------------------------------- |
| `batch_size`      | 100                  | Messages claimed per batch                                                                           |
| `poll_interval`   | 1                    | Seconds to sleep when nothing was due                                                                |
| `lease_duration`  | 300                  | Seconds a claimed message stays hidden from other relays. Must comfortably exceed a batch's delivery time; a shorter lease means a slow batch is delivered twice |
| `retry_policy`    | `RetryPolicy.new`    | When to retry and when to give up                                                                    |

`--require`, `--batch-size`, `--poll-interval`, `--lease-duration`, `--stats-interval` (`--no-stats` turns the notification off) and `--log-level` are available on the command line; what you don't give keeps the default of the relay. The database comes from `DATABASE_URL`, see [Security](https://railseventstore.org/docs/advanced-topics/outbox-relay#security).

## Going further

The [full documentation](https://railseventstore.org/docs/advanced-topics/outbox-relay) covers what this README leaves out:

- **Retries and dead letters** — the `RetryPolicy`, which failures are dead-lettered at once, and the `DeadLetters` API and rake tasks to list, requeue and discard.
- **Observability** — the `ActiveSupport::Notifications` the relay publishes (`process_batch`, `message_failed`, `stats`) and `Outbox#stats`.
- **Throughput** — measured numbers, bulk enqueue through `ActiveJobDispatcher`, batch size and lease.
- **Security** — least-privilege database grants, the hardened systemd unit, and the risk of `YAML.unsafe_load` in the default serializer. In short: the database comes from `DATABASE_URL`, never from an argument, and the relay resolves subscribers only through the `subscribe_async` registry.

## Guarantees

- **Atomicity.** An event and the outbox messages for its async subscribers are written in one transaction. If either write fails, neither persists, and sync subscribers are not notified.
- **At-least-once delivery, per subscriber.** A message is deleted only after its dispatch returned. A failure retries only that subscriber's message — the event's other subscribers are not called again. A relay that crashes after dispatching but before deleting redelivers once its lease runs out. Async subscribers must be idempotent by `event_id`.
- **Dispatch outside any transaction.** A slow or failing subscriber never holds database locks. A job enqueued by the dispatcher is never deferred until after the message is gone, so `enqueue_after_transaction_commit` in ActiveJob cannot lose it.
- **A message that can't be delivered can't block the queue.** It backs off, then goes to the dead letters.
- **No duplicated work across relay instances**, via `SELECT ... FOR UPDATE SKIP LOCKED` and leases.
- **Same metadata context as a synchronous publish** — `correlation_id`/`causation_id` are reproduced through `with_metadata` exactly as `Client#publish` does it.
- **No ordering guarantee.** Messages are claimed oldest first, but with several relays, retries and ActiveJob, handlers can observe events out of order.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RailsEventStore/rails_event_store.

## Releasing

1. Bump version
2. `make build`
3. `make push`

## License

MIT
