---
title: Instrumentation
---

RailsEventStore ships with built-in instrumentation. You can build your own features, improve logging or implement tracing on top of it. It can also be the way to integrate with 3rd party services for like NewRelic RPM, Skylight or AppSignal.

## Enabling instrumentation

### RubyEventStore

The `ruby_event_store` gem is not integrated with any particular instrumenter implementation. We don't enforce this dependency. Only require such instrumenter to have the same API as `ActiveSupport::Notifications`. One can for example use standalone [as-notifications](https://github.com/bernd/as-notifications) gem.

Instrumentation is provided by repository, mapper and dispatcher decorators:
* `RubyEventStore::InstrumentedRepository`
* `RubyEventStore::Mappers::InstrumentedMapper`
* `RubyEventStore::InstrumentedDispatcher`

In order to enable it, wrap the components you intend to instrument with corresponding decorators and instrumenter of your choice:

```ruby
instrumenter = ActiveSupport::Notifications

RubyEventStore::Client.new(
  repository: RubyEventStore::InstrumentedRepository.new(
    RubyEventStore::InMemoryRepository.new, instrumenter
  ),
  mapper: RubyEventStore::Mappers::InstrumentedMapper.new(
    RubyEventStore::Mappers::Default.new, instrumenter
  ),
  dispatcher: RubyEventStore::InstrumentedDispatcher.new(
    RubyEventStore::Dispatcher.new, instrumenter
  )
)
```

You can also instrument your own repository, mapper or dispatcher components the same way.

### RailsEventStore

The `rails_event_store` gem is integrated with `ActiveSupport::Notifications` that ships with Rails. By default `RailsEventStore::Client` instance ships with already instrumented repository, mapper and a dispatcher. 

You can start [subscribing](https://guides.rubyonrails.org/active_support_instrumentation.html#subscribing-to-an-event) to the instrumentation hooks by now:

```ruby
hook_name = "append_to_stream.repository.rails_event_store"

ActiveSupport::Notifications.subscribe(hook_name) do |name, start, finish, id, payload|
  metric = ActiveSupport::Notifications::Event.new(name, start, finish, id, payload)
  NewRelic::Agent.record_metric('Custom/RES/append_to_stream', metric.duration)
end
```

## Hooks and their payloads

#### append_to_stream.repository.rails_event_store

| Key     | Value                              |
| ------- | ---------------------------------- |
| :events | Array of appended events           |
| :stream | Name of stream we append events to |

#### link_to_stream.repository.rails_event_store

| Key        | Value                            |
| ---------- | -------------------------------- |
| :event_ids | Array of linked events' ids      |
| :stream    | Name of stream we link events to |

#### delete_stream.repository.rails_event_store

| Key     | Value                  |
| ------- | ---------------------- |
| :stream | Name of stream deleted |

#### read_event.repository.rails_event_store

| Key       | Value                |
| --------- | -------------------- |
| :event_id | Id of the read event |

#### read.repository.rails_event_store

| Key            | Value                                     |
| -------------- | ----------------------------------------- |
| :specification | Specification of the query to event store |

Queries specification is not documented, but you can read the [source code of it](https://github.com/RailsEventStore/rails_event_store/blob/master/ruby_event_store/lib/ruby_event_store/specification.rb).

#### call.dispatcher.rails_event_store

| Key         | Value                                        |
| ----------- | -------------------------------------------- |
| :event      | An event which is being dispatched           |
| :subscriber | A subscriber to which event is dispatched to |
