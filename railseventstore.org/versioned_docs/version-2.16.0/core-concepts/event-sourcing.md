---
title: Event Sourcing with AggregateRoot
sidebar_label: Event sourcing
---

## Configuration

Choose your event store client. To do so add configuration in your environment setup. Example using [RailsEventStore](https://github.com/RailsEventStore/rails_event_store/):

```ruby
AggregateRoot.configure do |config|
  config.default_event_store = RailsEventStore::Client.new
  # or
  config.default_event_store = Rails.configuration.event_store
end
```

Remember that this is only a default event store used by the `AggregateRoot` module to initialize `AggregateRoot::Repository` when no event store is given in the repository's constructor as an argument.

## Usage

To create a new aggregate domain object, include the `AggregateRoot` module.

```ruby
class Order
  include AggregateRoot

  # ... more later
end
```

### Define domain events

```ruby
class OrderSubmitted < RailsEventStore::Event; end
class OrderExpired < RailsEventStore::Event; end
```

### Define aggregate logic

```ruby
class Order
  include AggregateRoot
  class HasBeenAlreadySubmitted < StandardError; end
  class HasExpired < StandardError; end

  def initialize
    @state = :new
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

  on OrderSubmitted do |event|
    @state = :submitted
    @delivery_date = event.data.fetch(:delivery_date)
  end

  on OrderExpired do |event|
    @state = :expired
  end

  private

  attr_reader :state
end
```

### Alternative syntax for event handler methods (deprecated)

The convention is to use `apply_` plus an underscored event type (`event.event_type` what with `RubyEventStore::Event` is equal to event's class name) for event handler methods. I.e. when you apply the `OrderExpired` event, the `apply_order_expired` method is called. The downside is that you can't easily grep for usages of the event class.

```ruby
class Order
  include AggregateRoot
  class HasBeenAlreadySubmitted < StandardError; end
  class HasExpired < StandardError; end

  def initialize
    @state = :new
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
  attr_reader :state

  def apply_order_submitted(event)
    @state = :submitted
    @delivery_date = event.data.fetch(:delivery_date)
  end

  def apply_order_expired(event)
    @state = :expired
  end
end
```

### Loading an aggregate root object from an event store

```ruby
stream_name = "Order$123"
order = AggregateRoot::Repository.new.load(Order.new, stream_name)
```

To restore the state of your aggregate you need to use `AggregateRoot::Repository`. Repository's `#load` gets all domain events stored for the aggregate in the event store stream `Order$123` and applies them to the newly created order object in order to rebuild the aggregate's state.

### Storing an aggregate root's changes in an event store

```ruby
stream_name = "Order$123"
repository = AggregateRoot::Repository.new
order = repository.load(Order.new, stream_name)
order.submit
repository.store(order, stream_name)
```

Storing (publishing) aggregate changes is also performed by the `AggregateRoot::Repository` object. Repository's `#store` gets all the unpublished aggregate's domain events (added by executing a domain logic method like `submit`) from `unpublished_events` and publishes them in order of creation to the event store.

### Simplify loading/storing aggregates

`AggregateRoot::Repository` delivers a convenient method to handle a typical workflow with aggregates. The `with_aggregate` method will load an aggregate from a given stream, yield a block to allow performing an action on the aggregate object (the aggregate object will be yielded as a block argument), and then publish all changes in aggregate to the event store provided to the repository.

```ruby
stream_name = "Order$123"
repository = AggregateRoot::Repository.new
repository.with_aggregate(Order.new, stream_name) do |order|
  order.submit
end
```

You could also provide a specific repository for `Order` aggregate to make this code even better:

```ruby
class OrderRepository
  def initialize(event_store = Rails.configuration.event_store)
    @repository = AggregateRoot::Repository.new(event_store)
  end

  def with_order(order_id, &block)
    stream_name = "Order$#{order_id}"
    repository.with_aggregate(Order.new, stream_name, &block)
  end

  private
  attr_reader :repository
end
```

And then your code to submit an order might look like:

```ruby
repository = OrderRepository.new
repository.with_order(123) do |order|
  order.submit
end
```

## Overwriting default apply_strategy

You can change the way how aggregate methods are called in response to applied events. Let's say we want to call `order_has_expired` when the `OrderExpired` event is applied. To achieve this, we'll provide our implementation for the `apply_strategy` method:

```ruby
class Order
  include AggregateRoot
  class HasBeenAlreadySubmitted < StandardError; end
  class HasExpired < StandardError; end

  def initialize
    @state = :new
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
  attr_reader :state

  def apply_strategy
    ->(aggregate, event) do
      case event
      when OrderExpired
        order_has_expired
      when OrderSubmitted
        order_has_been_submitted
      else
        raise
      end
    end
  end

  def order_has_been_submitted(event)
    @state = :submitted
  end

  def order_has_expired(event)
    @state = :expired
  end
end
```

The `apply_strategy` method must return a _callable_ that responds to `#call`. We've used lambda in the example above. This lambda takes two arguments -- `aggreate` which in this case is `self` and an `event` being applied.

The `case` statement is one way to implement such a dispatch. The following example shows an equivalent implementation with `Hash`:

```ruby
def apply_strategy
    ->(aggregate, event) do
      {
        'OrderExpired' => method(:order_has_been_submitted),
        'OrderSubmitted' => method(:order_has_expired),
      }.fetch(event.event_type , ->(event) { raise }).call(event)
    end
  end

  def order_has_been_submitted(event)
    @state = :submitted
  end

  def order_has_expired(event)
    @state = :expired
  end
```

## Resources

There're already a few blog posts about building event sourced applications with [rails_event_store](https://github.com/RailsEventStore/rails_event_store) and `aggregate_root` gems:

- [Why use Event Sourcing](https://blog.arkency.com/2015/03/why-use-event-sourcing/)
- [The Event Store for Rails developers](https://blog.arkency.com/2015/04/the-event-store-for-rails-developers/)
- [Fast introduction to Event Sourcing for Ruby programmers](https://blog.arkency.com/2015/03/fast-introduction-to-event-sourcing-for-ruby-programmers/)
- [Building an Event Sourced application using rails_event_store](https://blog.arkency.com/2015/05/building-an-event-sourced-application-using-rails-event-store/)
- [Using domain events as success/failure messages](https://blog.arkency.com/2015/05/using-domain-events-as-success-slash-failure-messages/)
- [Subscribing for events in rails_event_store](https://blog.arkency.com/2015/06/subscribing-for-events-in-rails-event-store/)
- [Testing an Event Sourced application](https://blog.arkency.com/2015/07/testing-event-sourced-application/)
- [Testing Event Sourced application - the read side](https://blog.arkency.com/2015/09/testing-event-sourced-application-the-read-side/)
- [One event to rule them all](https://blog.arkency.com/2016/01/one-event-to-rule-them-all/)

Also [this example app](https://github.com/RailsEventStore/ecommerce) might be useful.
