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
         ▼                    └─ gave up / can never succeed ──▶ dead letters
   next_attempt_at
```

- **`event_store_outbox_messages`** — one row per (event, subscriber): `event_id`, `topic`, `subscriber` (the handler's class name), `attempts`, `next_attempt_at`, `last_error`. It only ever holds work still to do, so it stays small.
- **`event_store_outbox_dead_letters`** — deliveries that exhausted their attempts or can never succeed, with the error class, message and backtrace. See [Dead letters](#dead-letters).
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

The application uses the registered subscribers to decide which messages to write; the relay uses them to resolve a message's `subscriber` name back to a handler. It resolves names only through this registry — never by constant lookup — so a row in the outbox table can only ever reach a handler you registered. A message naming an unregistered subscriber is dead-lettered. Run the relay with the very client of your application (see below), so the list of async subscribers is defined once.

The subscriber must be a named class: its name is what the outbox stores. Unlike `subscribe_sync`, `subscribe_async` takes no block.

`async_subscriptions` defaults to `RubyEventStore::OutboxRelay::ActiveJobDispatcher` with the YAML serializer, so handlers must be ActiveJob classes; the relay enqueues each batch of jobs at once, see [Throughput](#throughput). Pass a different one at construction time:

```ruby
dispatcher = RubyEventStore::ImmediateDispatcher.new(scheduler: MyScheduler.new)
RubyEventStore::OutboxRelay::RailsClient.new(
  async_subscriptions: RubyEventStore::OutboxRelay::AsyncSubscriptions.new(dispatcher: dispatcher),
)
```

`publish(event, topic: "custom")` writes messages for the async subscribers of that topic, exactly as it notifies the sync subscribers of that topic.

## Installation (relay process)

The relay reads its subscriptions, outbox and mapper straight from a `Client` — the one of your application, so `subscribe_async` is called in one place only. Point the process at a file that loads the application and builds the relay, with `--require`:

```ruby
# config/outbox_relay.rb
require_relative "environment"

RubyEventStore::OutboxRelay::Configuration.configure do |batch_size:, poll_interval:, logger:|
  RubyEventStore::OutboxRelay::Relay.new(
    client: Rails.configuration.event_store,
    batch_size: batch_size,
    poll_interval: poll_interval,
    logger: logger,
  )
end
```

Synchronous subscribers of the client are never triggered by the relay. The relay refuses a client that isn't an outbox client, and at startup it logs the async subscribers of every topic, warning when there are none — in which case every message would be dead-lettered.

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

`--require`, `--batch-size`, `--poll-interval` and `--log-level` are available on the command line. The database comes from `DATABASE_URL`, see [Security](#security).

### Retries

`RetryPolicy.new(max_attempts: 25, base_delay: 1, max_delay: 3600, jitter: 0.2, permanent_errors: [])`. A failed dispatch is retried after `base_delay * 2^(attempt - 1)` seconds, capped at `max_delay` and stretched by up to `jitter`, so with the defaults a message is dead-lettered after roughly 13 hours. Errors listed in `permanent_errors` are dead-lettered on first occurrence.

One failing message never blocks the others: it moves out of the way by `next_attempt_at`, and the relay keeps claiming everything else that is due.

## Dead letters

A message goes to `event_store_outbox_dead_letters`, in one transaction with its removal from the outbox, when:

- its dispatch keeps failing until `max_attempts` (or fails with a permanent error);
- its event is no longer in the event store, or fails to deserialize;
- its subscriber is not registered in the relay process.

The last three can never succeed, so they skip retries. Each dead letter records `event_id`, `topic`, `subscriber`, `attempts`, `error_class`, `error_message` (first 1000 characters), `backtrace` (first 20 lines), `first_enqueued_at` and `dead_at`. The relay logs an `error` line for each one.

```ruby
dead_letters = RubyEventStore::OutboxRelay::DeadLetters.new

dead_letters.count
dead_letters.each { |dead_letter| puts [dead_letter.id, dead_letter.subscriber, dead_letter.error_class].join(" ") }

dead_letters.requeue(id)                                   # back to the outbox, attempts reset
dead_letters.requeue_all(topic: "OrderPlaced")             # optionally narrowed by topic and subscriber
dead_letters.discard(id)
```

Or from the command line:

```
bundle exec rake ruby_event_store:outbox_relay:dead_letters:list
bundle exec rake "ruby_event_store:outbox_relay:dead_letters:retry[42]"
TOPIC=OrderPlaced SUBSCRIBER=OrderReportJob bundle exec rake "ruby_event_store:outbox_relay:dead_letters:retry[all]"
bundle exec rake "ruby_event_store:outbox_relay:dead_letters:discard[42]"
```

## Observability

The relay reports through `ActiveSupport::Notifications`, under names ending in `.outbox_relay.ruby_event_store`. Pass another object responding to `instrument(name, payload)` as `instrumentation:` to send them elsewhere. Without subscribers they cost next to nothing.

| Notification | When | Payload |
| --- | --- | --- |
| `process_batch` | around each batch, idle ones included | `claimed`, `delivered`, `retried`, `dead` |
| `message_failed` | for each message that failed to be delivered | `outbox_id`, `event_id`, `topic`, `subscriber`, `attempts`, `error_class`, `outcome` (`:retried` or `:dead`) |
| `stats` | every `stats_interval` seconds (30 by default, `nil` turns it off) | `backlog`, `oldest_due_age`, `dead_letters` |

`message_failed` never carries the error's message, which can echo event data. The duration of a batch is the duration of its notification.

```ruby
ActiveSupport::Notifications.subscribe("process_batch.outbox_relay.ruby_event_store") do |event|
  StatsD.measure("outbox.batch", event.duration)
  StatsD.increment("outbox.delivered", event.payload[:delivered])
end

ActiveSupport::Notifications.subscribe("stats.outbox_relay.ruby_event_store") do |event|
  StatsD.gauge("outbox.oldest_due_age", event.payload[:oldest_due_age].to_f)
  StatsD.gauge("outbox.dead_letters", event.payload[:dead_letters])
end
```

`backlog` is the number of messages that are due, `oldest_due_age` the seconds the oldest of them has waited (`nil` when none is due) and `dead_letters` the number of dead letters. The two counts stop at 10,000, so measuring a huge backlog stays cheap. Messages being delivered are leased, hence not due. Alert on `oldest_due_age` growing, and on any `dead_letters`: they say the relay isn't keeping up, or that something can't be delivered. The same numbers are available to your own endpoint from `client.outbox.stats(now: Time.now.utc)`.

The relay logs, at `info`, its startup and shutdown and the async subscribers of every topic; at `warn`, each retry; at `error`, each dead letter, and a batch or stats query that failed, by exception class only; at `debug`, the counts of each batch that claimed something, and the message and backtrace of a failed batch.

## Throughput

Numbers below come from a laptop, a local PostgreSQL and the default YAML serializer, so read them as proportions, not promises.

- **Publishing.** A `publish` of events with async subscribers issues exactly one more statement than without them — one `INSERT` of the outbox messages, whatever the number of events published together, and none of it outside the transaction you already have. Publishing a batch amortizes even that. The events table is never updated afterwards, so it stays append-only.
- **One relay process** delivers about 8,000 messages per second to a subscriber that does nothing, and about 1,600 per second through ActiveJob. In the ActiveJob case most of the time goes to serializing each event for the job payload (a YAML dump of its metadata), not to the queue or the database. The relay is CPU-bound, so throughput scales with the number of relay processes, which share the outbox through `SKIP LOCKED`.
- **Bulk enqueue.** `ActiveJobDispatcher`, the default, enqueues a whole batch with a single `ActiveJob.perform_all_later`, which adapters turn into one round trip instead of one per job. With a simulated 0.2 ms round trip to the queue it raised throughput from about 1,070 to 1,740 messages per second for one subscriber per event, and from about 1,820 to 4,560 for three. With an in-memory adapter there is nothing to save. `perform_all_later` skips the enqueue callbacks (`before_enqueue`, `around_enqueue`, `after_enqueue`), so jobs that define any are enqueued one by one, with their callbacks. The adapter must mark the jobs it enqueued (`job.successfully_enqueued`), as ActiveJob's own adapters do. A dispatcher of your own gets the same treatment by responding to `call_all`, which takes an array of `AsyncSubscriptions::Delivery` and returns, for each, the error that kept it from being delivered, or `nil`.
- **Batch size and lease.** A bigger `batch_size` amortizes the claim and the delete, but beyond a few hundred it stops paying off, and a slow batch needs a longer `lease_duration`.
- **An idle relay** costs one short transaction per `poll_interval`. It sleeps only when nothing was due, so under load it never waits.

## Security

- **Database credentials never travel as arguments.** The relay reads the database from the `DATABASE_URL` environment variable; there is deliberately no `--database-url` option, because arguments are visible to every local user in the process list, `/proc/*/cmdline` and the journal. Under systemd, keep the variable in an `EnvironmentFile=` readable by root only (`chmod 600`), as the shipped unit does. `OUTBOX_RELAY_ARGS` of the rake task is split like a shell would.
- **Least privilege.** The relay only needs (verified on PostgreSQL) `SELECT` on `event_store_events`, `SELECT`, `UPDATE` and `DELETE` on `event_store_outbox_messages`, and `INSERT` on `event_store_outbox_dead_letters`. The application only needs `INSERT` on `event_store_outbox_messages`, on top of what it already has for the event store. Inserts never ask for the generated id (`RETURNING`), so no `SELECT` is needed on tables that are only written. Give the relay its own database role, and a separate one to whoever runs the dead letter tasks (`SELECT`, `UPDATE` and `DELETE` on the dead letters, because requeueing locks them with `FOR UPDATE`, and `INSERT` on the messages).
- **Only registered subscribers are ever called.** A message stores a subscriber's class name, but the relay resolves it through the `subscribe_async` registry only, never by constant lookup, so a row written to the outbox table cannot make it call an arbitrary class.
- **Deserialization is the relay's biggest attack surface.** The relay deserializes events read from the database with the repository's serializer. `RubyEventStore::Serializers::YAML`, the default of `RailsEventStore::Client`, loads with `YAML.unsafe_load`: anyone able to write to `event_store_events` (for example through an SQL injection elsewhere, or another service sharing the database) could make the relay, which holds database credentials and access to your job queue, execute code. Prefer the `JSON` serializer, and restrict write access to the events table to the applications that publish.
- **Logs stay free of event data.** A failing batch is logged by exception class only, and a failed or dead-lettered delivery by message id, event id, subscriber and exception class. The exception's message and backtrace are logged at `debug` level. Note that `last_error` on a message and `error_message` on a dead letter store the exception's message (truncated to 1000 characters), which can echo event data: treat both tables with the sensitivity of `event_store_events`.
- **Signal handlers are chained.** The relay handles `INT` and `TERM` to shut down gracefully and still calls any handler installed before it.
- **Hardened unit.** `support/systemd/res-outbox-relay.service` drops all capabilities, forbids privilege escalation and runs with a read-only file system, a private `/tmp`, no devices and restricted address families.

## Guarantees

- **Atomicity.** An event and the outbox messages for its async subscribers are written in one transaction. If either write fails, neither persists, and sync subscribers are not notified.
- **At-least-once delivery, per subscriber.** A message is deleted only after its dispatch returned. A failure retries only that subscriber's message — the event's other subscribers are not called again. A relay that crashes after dispatching but before deleting redelivers once its lease runs out. Async subscribers must be idempotent by `event_id`.
- **Dispatch outside any transaction.** A slow or failing subscriber never holds database locks. A job enqueued by the dispatcher is never deferred until after the message is gone, so `enqueue_after_transaction_commit` in ActiveJob cannot lose it.
- **A message that can't be delivered can't block the queue.** It backs off, then goes to the dead letters.
- **No duplicated work across relay instances**, via `SELECT ... FOR UPDATE SKIP LOCKED` and leases.
- **Same metadata context as a synchronous publish** — `correlation_id`/`causation_id` are reproduced through `with_metadata` exactly as `Client#publish` does it.
- **No ordering guarantee.** Messages are claimed oldest first, but with several relays, retries and ActiveJob, handlers can observe events out of order.

See the [full documentation](https://railseventstore.org/docs/advanced-topics/outbox-relay) for the underlying design and more examples.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RailsEventStore/rails_event_store.

## Releasing

1. Bump version
2. `make build`
3. `make push`

## License

MIT
