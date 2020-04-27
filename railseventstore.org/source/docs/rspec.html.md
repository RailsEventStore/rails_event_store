---
title: RSpec matchers
---

## Adding matchers to the project

Add this line to your application's Gemfile:

```ruby
group :test do
  gem 'rails_event_store-rspec'
end
```

## Matchers usage

### be_event

The `be_event` matcher enables you to make expectations on a domain event. It exposes fluent interface.

```ruby
OrderPlaced  = Class.new(RailsEventStore::Event)
domain_event = OrderPlaced.new(
  data: {
    order_id: 42,
    net_value: BigDecimal.new("1999.0")
  },
  metadata: {
    remote_ip: '1.2.3.4'
  }
)

expect(domain_event)
  .to(be_an_event(OrderPlaced)
    .with_data(order_id: 42, net_value: BigDecimal.new("1999.0"))
    .with_metadata(remote_ip: '1.2.3.4'))
```

By default the behaviour of `with_data` and `with_metadata` is not strict, that is the expectation is met when all specified values for keys match. Additional data or metadata that is not specified to be expected does not change the outcome.

```ruby
domain_event = OrderPlaced.new(
  data: {
    order_id: 42,
    net_value: BigDecimal.new("1999.0")
  }
)

# this would pass even though data contains also net_value
expect(domain_event).to be_an_event(OrderPlaced).with_data(order_id: 42)
```

This matcher is both [composable](http://rspec.info/blog/2014/01/new-in-rspec-3-composable-matchers/) and accepting [built-in matchers](https://relishapp.com/rspec/rspec-expectations/v/3-6/docs/built-in-matchers) as a part of an expectation.

```ruby
expect(domain_event).to be_an_event(OrderPlaced).with_data(order_id: kind_of(Integer))
expect([domain_event]).to include(an_event(OrderPlaced))
```

If you depend on matching the exact data or metadata, there's a `strict` modifier.

```ruby
domain_event = OrderPlaced.new(
  data: {
    order_id: 42,
    net_value: BigDecimal.new("1999.0")
  }
)

# this would fail as data contains unexpected net_value
expect(domain_event).to be_an_event(OrderPlaced).with_data(order_id: 42).strict
```

Mind that `strict` makes both `with_data` and `with_metadata` behave in a stricter way. If you need to mix both, i.e. strict data but non-strict metadata then consider composing matchers.

```ruby
expect(domain_event)
  .to(be_event(OrderPlaced).with_data(order_id: 42, net_value: BigDecimal.new("1999.0")).strict
    .and(an_event(OrderPlaced).with_metadata(timestamp: kind_of(Time)))
```

You may have noticed the same matcher being referenced as `be_event`, `be_an_event` and `an_event`. There's also just `event`. Use whichever reads better grammatically.

### have_published

Use this matcher to target `event_store` and reading from streams specifically.
In a simplest form it would read all streams forward and check whether the expectation holds true. Its behaviour can be best compared to the `include` matcher — it is satisfied by at least one element present in the collection. You're encouraged to compose it with `be_event`.

```ruby
event_store = RailsEventStore::Client.new
event_store.publish(OrderPlaced.new(data: { order_id: 42 }))

expect(event_store).to have_published(an_event(OrderPlaced))
```

Expectation can be narrowed to the specific stream.

```ruby
event_store = RailsEventStore::Client.new
event_store.publish(OrderPlaced.new(data: { order_id: 42 }), stream_name: "Order$42")

expect(event_store).to have_published(an_event(OrderPlaced)).in_stream("Order$42")
```

It is sometimes important to ensure that specific amount of events of given type have been published. Luckily there's a modifier to cover that usecase.

```ruby
expect(event_store).not_to have_published(an_event(OrderPlaced)).once
expect(event_store).to have_published(an_event(OrderPlaced)).exactly(2).times
```

You can make expectation on several events at once.

```ruby
expect(event_store).to have_published(
  an_event(OrderPlaced),
  an_event(OrderExpired).with_data(expired_at: be_between(Date.yesterday, Date.tomorrow))
)
```

You can also make expectation to ensure that expected list of events is exact actual list of events (and in the same order) using `strict` modifier.

```ruby
expect(event_store).to have_published(
  an_event(OrderPlaced),
  an_event(OrderExpired).with_data(expired_at: be_between(Date.yesterday, Date.tomorrow))
).strict
```

Last but not least, you can specify reading starting point for matcher.

```ruby
expect(event_store).to have_published(
  an_event(OrderExpired)
).from(order_placed.event_id)
```

If there's a usecase not covered by examples above or you need a different set of events to make expectations on you can always resort to a more verbose approach and skip `have_published`.

```ruby
expect(event_store.read.stream("OrderAuditLog$42").limit(2)).to eq([
  an_event(OrderPlaced),
  an_event(OrderExpired)
])
```

### publish

This matcher is similar to `have_published` one, but targets only events published in given execution block.

```ruby
event_store = RailsEventStore::Client.new
expect {
  event_store.publish(OrderPlaced.new(data: { order_id: 42 }))
}.to publish(an_event(OrderPlaced)).in(event_store)
```

Expectation can be narrowed to the specific stream.

```ruby
event_store = RailsEventStore::Client.new
expect {
  event_store.publish(OrderPlaced.new(data: { order_id: 42 }), stream_name: "Order$42")
}.to publish(an_event(OrderPlaced)).in(event_store).in_stream("Order$42")

```

You can make expectation on several events at once.

```ruby
expect {
  # ...tested code here
}.to publish(
  an_event(OrderPlaced),
  an_event(OrderExpired).with_data(expired_at: be_between(Date.yesterday, Date.tomorrow))
).in(event_store)
```


## AggregateRoot matchers

The matchers described below are intended to be used on [aggregate root](https://github.com/RailsEventStore/rails_event_store/tree/master/aggregate_root#usage).

To explain the usage of matchers sample aggregate class is defined:

```ruby
class Order
  include AggregateRoot
  HasBeenAlreadySubmitted = Class.new(StandardError)
  HasExpired              = Class.new(StandardError)

  def initialize
    self.state = :new
    # any other code here
  end

  def submit
    raise HasBeenAlreadySubmitted if state == :submitted
    raise HasExpired if state == :expired
    apply OrderSubmitted.new(data: {delivery_date: Time.now + 24.hours})
  end

  def expire
    apply OrderExpired.new
  end

  private
  attr_accessor :state

  def apply_order_submitted(event)
    self.state = :submitted
  end

  def apply_order_expired(event)
    self.state = :expired
  end
end
```

The matchers behaviour is almost identical to `have_published` & `publish` counterparts, except the concept of stream. Expecations are made against internal unpublished events collection.

### have_applied

This matcher check if an expected event has been applied in `aggregate_root` object.

```ruby
aggregate_root = Order.new
aggregate_root.submit

expect(aggregate_root).to have_applied(event(OrderSubmitted))
```

You could define expectations how many events have been applied by using:

```ruby
expect(aggregate_root).to have_applied(event(OrderSubmitted)).once
expect(aggregate_root).to have_applied(event(OrderSubmitted)).exactly(3).times
```

With `strict` option it checks if only expected events have been applied.

```ruby
expect(aggregate_root).to have_applied(event(OrderSubmitted)).strict
```

### apply

This matcher is similar to `have_applied`. It check if expected event is applied
in given `aggregate_root` object but only during execution of code block.

```ruby
aggregate_root = Order.new
aggregate_root.submit

expect {
  aggregate_root.expire
}.to apply(event(OrderExpired)).in(aggregate_root)
```

With `strict` option it checks if only expected events have been applied in given execution block.

```ruby
aggregate_root = Order.new
aggregate_root.submit

expect {
  aggregate_root.expire
}.to apply(event(OrderExpired)).in(aggregate_root).strict
```
