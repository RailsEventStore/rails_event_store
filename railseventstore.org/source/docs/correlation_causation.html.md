# Correlating messages (events and commands)

Debugging can be one of the challenges when building asynchronous, evented systems. _Why did this happen, what caused all of that?_. But there are patterns which might make your life easier. We just need to keep track of what is happening as a result of what.

For that, you can use 2 metadata attributes associated with events you are going to publish.

Let's hear what Greg Young says about `correlation_id` and `causation_id`:

> Let's say every message has 3 ids. 1 is its id. Another is correlation the last it causation. 
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
      
      event_store.publish_event(new_event)   
    end
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
      event_store.publish_events([
        MyEvent.new(data: {foo: 'bar'}),
        AnotherEvent.new(data: {baz: 'bax'}),
      ])   
    end
  end
end
```

Image thanks to [Arkency blog](https://blog.arkency.com/correlation-id-and-causation-id-in-evented-systems/)