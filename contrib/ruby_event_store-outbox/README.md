# Ruby Event Store Outbox

![Ruby Event Store Outbox](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-outbox/badge.svg)

**Experimental feature of RES ecosystem.**

This repository includes a process and a Rails Event Store scheduler, which can be used to transactionally enqueue background jobs into your background jobs tool of choice. The scheduler included in this repo adds the jobs into the RDBMS into specific table instead of redis inside your transaction, and the process is enqueuing the jobs from that table to the background jobs tool.

## Installation (app)

Add to your gemfile in application:

```ruby
gem "ruby_event_store-outbox"
```

Generate and execute the migration adding necessary tables. If it's needed, change the type of the `payload` column to `mediumbinary` or `longbinary`.

```
bin/rails generate ruby_event_store:outbox:migration
```

In your event store configuration, as a dispatcher use `RubyEventStore::ImmediateAsyncDispatcher` with `RubyEventStore::Outbox::SidekiqScheduler`, for example:

```ruby

RailsEventStore::Client.new(
  dispatcher: RailsEventStore::ImmediateAsyncDispatcher.new(scheduler: RubyEventStore::Outbox::SidekiqScheduler.new),
  ...
)
```

Additionally, your handler's `through_outbox?` method should return `true`, for example:

```ruby
class SomeHandler
  def self.through_outbox?; true; end
end
```


## Installation (outbox process)

Run following process in any way you prefer:

```
res_outbox \
  --database-url="mysql2://root@0.0.0.0:3306/my_database" \
  --redis-url="redis://localhost:6379/0" \
  --log-level=info \
  --split-keys=sidekiq_queue1,sidekiq_queue2
```

It is possible to run as many instances as you prefer, but it does not make sense to run more instances than there are different split keys (sidekiq queues), as one process is operating at one moment only one split key.

### Metrics

It is possible for the outbox process to send metrics to InfluxDB (this requires influxdb gem in version at least 0.8.1). In order to do that, specify a `--metrics-url` parameter, for example:

```
res_outbox --database-url="mysql2://root@0.0.0.0:3306/my_database" \
  --redis-url="redis://localhost:6379/0" \
  --log-level=info \
  --split-keys=sidekiq_queue1,sidekiq_queue2 \
  --metrics-url=http://user:password@localhost:8086/dbname"
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RailsEventStore/rails_event_store.

## Releasing

1. Bump version
2. `make build`
3. `make push`
4. `make docker-build`
5. `make docker-push`
