# Ruby Event Store Sidekiq Scheduler

A library to schedule Ruby Event Store handlers to sidekiq.

![Ruby Event Store Sidekiq Scheduler](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-sidekiq_scheduler/badge.svg)

## How to use this gem

Add to your gemfile in application:

```ruby
gem "ruby_event_store-sidekiq_scheduler"
```

Declare the scheduler in your Ruby Event Store configuration. We recommend to use it with `AfterCommitAsyncDispatcher`

```ruby
event_store = RailsEventStore::Client.new(
  dispatcher: RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: RubyEventStore::SidekiqScheduler.new),
)
```

Read more about [using asynchronous handlers](https://railseventstore.org/docs/v2/subscribe/#async-handlers)


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RailsEventStore/rails_event_store.
