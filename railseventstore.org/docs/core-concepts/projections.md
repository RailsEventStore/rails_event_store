---
title: Projections
---

You can build a projection over a single stream. Define the initial state with `init`,
register handlers with `on`, then run it by passing a read scope to `call`.

```ruby
stream_name = "Customer$1"

client.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
client.publish(custom_event = MoneyDeposited.new(data: { amount: 20 }), stream_name: stream_name)
client.publish(MoneyWithdrawn.new(data: { amount: 5 }), stream_name: stream_name)

account_balance =
  RubyEventStore::Projection
    .init({ total: 0 })
    .on(MoneyDeposited) { |state, event| { total: state[:total] + event.data[:amount] } }
    .on(MoneyWithdrawn) { |state, event| { total: state[:total] - event.data[:amount] } }

account_balance.call(client.read.stream(stream_name)) # => {total: 25}
```

The stream to project over is the scope you pass to `call`. To narrow the results, pass
a scope starting after a given event:

```ruby
account_balance.call(client.read.stream(stream_name).from(custom_event.event_id)) # => {total: -5}
```

You may also subscribe one handler to multiple events by passing them all to `on`:

```ruby
account_cashflow =
  RubyEventStore::Projection
    .init({ total: 0 })
    .on(MoneyDeposited, MoneyWithdrawn) { |state, event| { total: state[:total] + event.data[:amount] } }

account_cashflow.call(client.read) # => {total: 35}
```

## Projection based on all streams

Pass an all-streams read scope (`client.read`) to `call` instead of a single stream.

```ruby
client.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$1")
client.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$2")
client.publish(custom_event = MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$3")
client.publish(MoneyWithdrawn.new(data: { amount: 20 }), stream_name: "Customer$4")

account_balance =
  RubyEventStore::Projection
    .init({ total: 0 })
    .on(MoneyDeposited) { |state, event| { total: state[:total] + event.data[:amount] } }
    .on(MoneyWithdrawn) { |state, event| { total: state[:total] - event.data[:amount] } }

account_balance.call(client.read) # => {total: 10}
account_balance.call(client.read.from(custom_event.event_id)) # => {total: -20}
```
