---
title: Correlation and Causation
---

Debugging can be one of the challenges when building asynchronous, evented systems. _Why did this happen, what caused all of that?_. But there are patterns which might make your life easier. We just need to keep track of what is happening as a result of what.

For that, you can use 2 metadata attributes associated with events you are going to publish.

Let's hear what Greg Young says about `correlation_id` and `causation_id`:

> Let's say every message has 3 ids. 1 is its id. Another is correlation, the last is causation.
> If you are responding to a message, you copy its correlation id as your correlation id, its message id is your causation id.
> This allows you to see an entire conversation (correlation id) or to see what causes what (causation id).

Now, the message that you are responding to can be either a command or an event which triggered some event handlers and probably caused even more events.

![CorrelationAndCausationEventsCommands](https://blog-arkency.imgix.net/correlation_id_causation_id_rails_ruby_event/CorrelationAndCausationEventsCommands.png?w=758&h=758&fit=max)

## Correlating one event with another

```ruby
class MyEventHandler
  def call(previous_event)
    new_event = MyEvent.new(data: {foo: 'bar'})
    new_event.correlate_with(previous_event)

    event_store.publish(new_event)
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
```

After using `correlate_with` you can access UUIDs of related events via two getters:

```ruby
new_event.correlation_id
```

and

```ruby
new_event.causation_id
```

They are also available as:

```ruby
new_event.metadata[:correlation_id]
new_event.metadata[:causation_id]
```

This is however not necessary for sync handlers. Events published from sync handlers are by default correlated with events that caused them.

## Correlating events published from async handlers

Events published from async handlers are not correlated with events that caused them by default. To enable that functionality you need to prepend `RailsEventStore::CorrelatedHandler`

```ruby
class SendOrderEmail < ActiveJob::Base
  prepend RailsEventStore::CorrelatedHandler
  prepend RailsEventStore::AsyncHandler

  def perform(event)
    event_store.publish(HappenedLater.new(data:{
      user_id: event.data.fetch(:user_id),
    }))
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
```

## Correlating an event with a command

If your command responds to `correlation_id` (can even always be `nil`) and `message_id` you can correlate your events also with commands.

```ruby
class ApproveOrder < Struct.new(:order_id, :message_id, :correlation_id)
end

command = ApproveOrder.new("KTXBN123", SecureRandom.uuid, nil)
event = OrderApproved.new(data: {foo: 'bar'})
event.correlate_with(command)
```

## Correlating multiple events

```ruby
class MyEventHandler
  def call(previous_event)
    event_store.with_metadata(
      correlation_id: previous_event.correlation_id || previous_event.event_id,
      causation_id:   previous_event.event_id
    ) do
      event_store.publish([
        MyEvent.new(data: {foo: 'bar'}),
        AnotherEvent.new(data: {baz: 'bax'}),
      ])
    end
  end
end
```

## Correlating together events with commands, and commands with events from sync handlers

If you use event store and [command bus](/docs/v1/command_bus/) you can correlate together both kinds of messages: events & commands.

```ruby
config.to_prepare do
  Rails.configuration.event_store = event_store = RailsEventStore::Client.new
  # register handlers

  command_bus = Arkency::CommandBus.new
  # register commands...

  # wire event_store and command_bus together
  Rails.configuration.command_bus = RubyEventStore::CorrelatedCommands.new(event_store, command_bus)
end
```

Using `CorrelatedCommands` makes your events automatically correlated to the commands which triggered them (commands must respond to `message_id` method).

If your commands respond to `correlate_with` method they will be correlated to events which triggered them inside sync handlers.

Example:

```ruby
module CorrelableCommand
  attr_accessor :correlation_id, :causation_id

  def correlate_with(other_message)
    self.correlation_id = other_message.correlation_id || other_message.message_id
    self.causation_id   = other_message.message_id
  end
end

class AddProductCommand < Struct.new(:message_id, :product_id)
  include CorrelableCommand

  def initialize(product_id:, message_id: SecureRandom.uuid)
    super(message_id, product_id)
  end
end
```

## Building streams based on correlation id and causation id

You can use `RailsEventStore::LinkByCorrelationId` (`RubyEventStore::LinkByCorrelationId`) and `RailsEventStore::LinkByCausationId` (`RubyEventStore::LinkByCausationId`) to build streams of all events with certain correlation or causation id. This makes debugging and making sense of a large process easier to see.

```ruby
Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = event_store = RailsEventStore::Client.new
    event_store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    event_store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
  end
end
```

After publishing an event:

```ruby
event = OrderPlaced.new
event_store.publish(event)
```

you can read events caused by it:

```ruby
event_store.read.stream("$by_causation_id_#{event.event_id}")
```

and events correlated with it:

```ruby
event_store.read.stream("$by_correlation_id_#{event.correlation_id || event.event_id}")
```

## Thanks

Image thanks to [Arkency blog](https://blog.arkency.com/correlation-id-and-causation-id-in-evented-systems/)
