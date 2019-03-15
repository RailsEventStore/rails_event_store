---
title: Projections
---

You can create a projection abstract based on single stream.

```ruby
stream_name = "Customer$1"

client.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
client.publish(custom_event = MoneyDeposited.new(data: { amount: 20 }), stream_name: stream_name)
client.publish(MoneyWithdrawn.new(data: { amount: 5 }), stream_name: stream_name)

account_balance = RailsEventStore::Projection.
  from_stream(stream_name).
  init(-> { { total: 0 } }).
  when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] }).
  when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.data[:amount] })

account_balance.run(client) # => {total: 25}
```

In order to narrow the results, simply pass `event_id` to `run` method.

```ruby
account_balance.run(client, start: custom_event.event_id) # => {total: -5}
```

You may also subscribe one handler to multiple events by passing an array to `#when` method:

```ruby
account_cashflow = RailsEventStore::Projection.
  from_all_streams.
  init( -> { { total: 0 } }).
  when([MoneyDeposited, MoneyWithdrawn], ->(state, event) { state[:total] += event.data[:amount] })

account_cashflow.run(client) # => {total: 35}
```

## Projection based on multiple streams

```ruby
client.publish(MoneyDeposited.new(data: { amount: 15 }), stream_name: "Customer$1")
client.publish(MoneyDeposited.new(data: { amount: 25 }), stream_name: "Customer$2")
client.publish(custom_event = MoneyWithdrawn.new(data: { amount: 10 }), stream_name: "Customer$3")
client.publish(MoneyWithdrawn.new(data: { amount: 20 }), stream_name: "Customer$3")

account_balance = RailsEventStore::Projection.
  from_stream("Customer$1", "Customer$3").
  init( -> { { total: 0 } }).
  when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] }).
  when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.data[:amount] })

account_balance.run(client) # => {total: -15}
```

In order to narrow the results, you have to pass array with `event_id` for each stream or nil to start from beggining of the stream. So, in example below we start from beggining of stream for `Customer$1` and `custom_event.event_id` for `Customer$3`.

```ruby
account_balance.run(client, start: [nil, custom_event.event_id]) # => {total: -5}
```

## Projection based on all streams

```ruby
client.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$1")
client.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$2")
client.publish(custom_event = MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$3")
client.publish(MoneyWithdrawn.new(data: { amount: 20 }), stream_name: "Customer$4")

account_balance = RailsEventStore::Projection.
  from_all_streams.
  init( -> { { total: 0 } }).
  when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] }).
  when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.data[:amount] })

account_balance.run(client) # => {total: 10}
account_balance.run(client, start: custom_event.event_id) # => {total: -20}
```
