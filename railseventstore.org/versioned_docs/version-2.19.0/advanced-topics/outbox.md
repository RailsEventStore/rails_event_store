---
title: Transactional outbox
sidebar_label: Outbox
---

The `ruby_event_store-outbox` gem provides a way to enqueue background jobs transactionally. Instead of writing to Redis directly inside your transaction (which can leave jobs enqueued for events that later roll back), the scheduler writes the job into the same database table within the same transaction. A separate `res_outbox` process then drains that table to your background jobs tool.

## Installation (app)

Add to your Gemfile:

```ruby
gem "ruby_event_store-outbox"
```

Generate and execute the migration adding the necessary tables. If needed, change the type of the `payload` column to `mediumbinary` or `longbinary`.

```
bin/rails generate ruby_event_store:outbox:migration
```

In your event store configuration, use `RubyEventStore::ImmediateAsyncDispatcher` with `RubyEventStore::Outbox::SidekiqScheduler`:

```ruby
RailsEventStore::Client.new(
  dispatcher: RailsEventStore::ImmediateAsyncDispatcher.new(scheduler: RubyEventStore::Outbox::SidekiqScheduler.new),
  ...
)
```

Your handler's `through_outbox?` method must return `true`:

```ruby
class SomeHandler
  include Sidekiq::Worker

  def self.through_outbox?
    true
  end

  def perform(payload)
    # handle the event
  end
end
```

## Installation (outbox process)

Run the following process in any way you prefer:

```
res_outbox \
  --database-url="mysql2://root@0.0.0.0:3306/my_database" \
  --redis-url="redis://localhost:6379/0" \
  --log-level=info \
  --split-keys=sidekiq_queue1,sidekiq_queue2
```

It is possible to run as many instances as you prefer, but it does not make sense to run more instances than there are different split keys (sidekiq queues), as one process is operating at one moment only one split key.

### Split keys

A split key is the Sidekiq queue name. Each outbox record is stored with the queue name of the target worker as its split key. The `res_outbox` process picks up records matching the split keys it is configured to handle.

When `--split-keys` is omitted, the process handles all queues. When running multiple instances, assign a distinct subset of queues to each instance — there is no benefit to having more instances than queues, since one process handles only one split key at a time.

### Options

| Option              | Required | Default  | Description                                                                                               |
| ------------------- | -------- | -------- | --------------------------------------------------------------------------------------------------------- |
| `--database-url`    | yes      | —        | Database where the outbox table is stored                                                                 |
| `--redis-url`       | yes      | —        | URL to the Redis database                                                                                 |
| `--split-keys`      | no       | all      | Comma-separated list of split keys (Sidekiq queues) to handle                                            |
| `--batch-size`      | no       | 100      | Number of records fetched per iteration. Larger values increase the risk of duplicates on network failure |
| `--sleep-on-empty`  | no       | 0.5      | Seconds to sleep before next check when there was nothing to process                                      |
| `--[no-]lock`       | no       | enabled  | Use distributed locking per split key. Disable with `--no-lock` to use `SKIP LOCKED` instead             |
| `--cleanup`         | no       | none     | Strategy for removing old enqueued records. Use ISO 8601 duration (e.g. `P7D` for 7 days) or `none`      |
| `--cleanup-limit`   | no       | all      | Number of records removed per cleanup run, or `all`                                                       |
| `--log-level`       | no       | warn     | One of: `fatal`, `error`, `warn`, `info`, `debug`                                                         |
| `--message-format`  | no       | sidekiq5 | Message format. Currently only `sidekiq5` is supported                                                    |
| `--metrics-url`     | no       | —        | URI to InfluxDB metrics collector                                                                         |

### Metrics

It is possible for the outbox process to send metrics to InfluxDB (this requires the `influxdb` gem in version at least 0.8.1). Specify a `--metrics-url` parameter:

```
res_outbox --database-url="mysql2://root@0.0.0.0:3306/my_database" \
  --redis-url="redis://localhost:6379/0" \
  --log-level=info \
  --split-keys=sidekiq_queue1,sidekiq_queue2 \
  --metrics-url=http://user:password@localhost:8086/dbname
```
