# AggregateRoot

Event sourced (with Rails Event Store) aggregate root implementation.

## Installation

* Add following line to your application's Gemfile:

```ruby
gem 'aggregate_root'
```

## Usage

To create a new aggregate domain object include `AggregateRoot::Base` module.
It is important to assign `id` at initializer - it will be used as a event store stream name.

```ruby
class Order
  include AggregateRoot::Base

  def initialize(id = generate_id)
    self.id = id
    # any other code here
  end

  # ... more later
end
```

#### Define aggregate logic

```ruby
OrderSubmitted = Class.new(RailsEventStore::Event)
OrderExpired   = Class.new(RailsEventStore::Event)
```

```ruby
class Order
  include AggregateRoot::Base
  HasBeenAlreadySubmitted = Class.new(StandardError)
  HasExpired              = Class.new(StandardError)

  def initialize(id = generate_id)
    self.id = id
    self.state = :new
    # any other code here
  end

  def submit
    raise HasBeenAlreadySubmitted if state == :submitted
    raise HasExpired if state == :expired
    apply OrderSubmitted.new(delivery_date: Time.now + 24.hours)
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

#### Loading an aggregate root object from event store

```ruby
repository = ArggregateRoot::Repository.new
order = Order.new(ORDER_ID)
repository.load(order)
```

Load gets all domain event stored for the aggregate in event store and apply them
in order to given aggregate to rebuild aggregate's state.

#### Storing an aggregate root's changes in event store

```ruby
repository = ArggregateRoot::Repository.new
order = Order.new(ORDER_ID)
repository.load(order)
order.submit
repository.store(order)
```

Store gets all unpublished aggregate's domain events (created by executing a domain logic method like `submit`)
and publish them in order of creation to event store.

#### Resources

There're already few blogposts about Rails EventStore. Check them out:

* [Why use Event Sourcing](http://blog.arkency.com/2015/03/why-use-event-sourcing/)
* [The Event Store for Rails developers](http://blog.arkency.com/2015/04/the-event-store-for-rails-developers/)
* [Fast introduction to Event Sourcing for Ruby programmers](http://blog.arkency.com/2015/03/fast-introduction-to-event-sourcing-for-ruby-programmers/)

## About

<img src="http://arkency.com/images/arkency.png" alt="Arkency" width="20%" align="left" />

Rails Event Store is funded and maintained by Arkency. Check out our other [open-source projects](https://github.com/arkency).

You can also [hire us](http://arkency.com) or [read our blog](http://blog.arkency.com).
