# Ruby Event Store Outbox

Very much work in progress.


## Installation (app)

Add to your gemfile in application:

```ruby
gem "ruby_event_store-outbox"
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
res_outbox --database-url="mysql2://root@0.0.0.0:3306/my_database" --redis-url="redis://localhost:6379/0" --log-level=info
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RailsEventStore/rails_event_store.
