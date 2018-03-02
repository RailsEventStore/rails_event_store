# AggregateRoot

Event sourced (with Rails Event Store) aggregate root implementation.

## Configuration

Choose your event store client. To do so add configuration in environment setup. Example using [RailsEventStore](https://github.com/RailsEventStore/rails_event_store/):

```ruby
AggregateRoot.configure do |config|
  config.default_event_store = RailsEventStore::Client.new
  # or
  config.default_event_store = Rails.configuration.event_store 
end
```

Remember that this is only a default event store used by `AggregateRoot` module when no event store is given in `load` / `store` methods parameters.

## Usage

To create a new aggregate domain object include `AggregateRoot` module.

```ruby
class Order
  include AggregateRoot

  # ... more later
end
```

#### Define domain events

```ruby
class OrderSubmitted < RailsEventStore::Event; end
class OrderExpired < RailsEventStore::Event; end
```

#### Define aggregate logic

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
  end

  def apply_order_expired(event)
    @state = :expired
  end
end
```

The convention is to use `apply_` plus an underscored event class name for event handler methods. I.e. when you apply `OrderExpired` event, the `apply_order_expired` method is called.

#### Alternative syntax for event handler methods.

You can use class method `on(event_klass, &method)` for defining those methods alternatively. This is useful because you can more easily grep/find where events are used in your codebase.

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
    @delivery_date = evet.data.fetch(:delivery_date)
  end

  on OrderExpired do |event|
    @state = :expired
  end

  private
  
  attr_reader :state
end
```

#### Loading an aggregate root object from event store

```ruby
stream_name = "Order$123"
order = Order.new.load(stream_name)
```

`#load` gets all domain events stored for the aggregate in event store and applies them in order to rebuild aggregate's state.

#### Storing an aggregate root's changes in event store

```ruby
stream_name = "Order$123"
order = Order.new.load(stream_name)
order.submit
order.store
```

`#store` gets all unpublished aggregate's domain events  (added by executing a domain logic method like `submit`) from `unpublished_events` and publishes them in order of creation to event store. If `stream_name` is not specified events will be stored in the same stream from which the aggregate has been loaded.

## Overwriting default apply_strategy

TODO: Describe me!

## API

### Instance methods

#### Public

```ruby
apply(*events)
```

```ruby
load(stream_name, event_store: AggregateRoot.configuration.default_event_store)
```

```ruby
store(stream_name = @loaded_from_stream_name, event_store: AggregateRoot.configuration.default_event_store)
```

```ruby
unpublished_events()
```

#### Private

```ruby
apply_strategy()
```

```ruby
default_event_store()
```


#### Class methods

```ruby
on(event_class, &method)
```

## Resources

There're already few blog posts about building an event sourced applications with [rails_event_store](https://github.com/RailsEventStore/rails_event_store) and `aggregate_root` gems:

* [Why use Event Sourcing](https://blog.arkency.com/2015/03/why-use-event-sourcing/)
* [The Event Store for Rails developers](https://blog.arkency.com/2015/04/the-event-store-for-rails-developers/)
* [Fast introduction to Event Sourcing for Ruby programmers](https://blog.arkency.com/2015/03/fast-introduction-to-event-sourcing-for-ruby-programmers/)
* [Building an Event Sourced application using rails_event_store](https://blog.arkency.com/2015/05/building-an-event-sourced-application-using-rails-event-store/)
* [Using domain events as success/failure messages](https://blog.arkency.com/2015/05/using-domain-events-as-success-slash-failure-messages/)
* [Subscribing for events in rails_event_store](https://blog.arkency.com/2015/06/subscribing-for-events-in-rails-event-store/)
* [Testing an Event Sourced application](https://blog.arkency.com/2015/07/testing-event-sourced-application/)
* [Testing Event Sourced application - the read side](https://blog.arkency.com/2015/09/testing-event-sourced-application-the-read-side/)
* [One event to rule them all](https://blog.arkency.com/2016/01/one-event-to-rule-them-all/)

Also [this example app](https://github.com/mpraglowski/cqrs-es-sample-with-res) might be useful.