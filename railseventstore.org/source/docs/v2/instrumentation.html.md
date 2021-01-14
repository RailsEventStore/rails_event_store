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

| Key     | Value |
| ------- | ----- |
| :events | An array of appended [RubyEventStore::Record](https://www.rubydoc.info/gems/ruby_event_store/RubyEventStore/Record) objects |
| :stream | A [RubyEventStore::Stream](https://www.rubydoc.info/gems/ruby_event_store/RubyEventStore/Stream) that we append events to |

```ruby
{
  events: [#<RubyEventStore::Record:0x0000000104b51f30>],
  stream: #<RubyEventStore::Stream:0x0000000106cbf578>
}
```


#### link_to_stream.repository.rails_event_store

| Key        | Value |
| ---------- | ----- |
| :event_ids | An array of linked event identifiers |
| :stream    | A [RubyEventStore::Stream](https://www.rubydoc.info/gems/ruby_event_store/RubyEventStore/Stream) that we link events to |

```ruby
{
  event_ids: ["71c38b38-4c72-4f95-86e2-203898f98c8e",
   "82dcf1eb-ec4e-48c6-b061-de7ce03fb6af"],
  stream: #<RubyEventStore::Stream:0x0000000106cbf578>
}
```


#### delete_stream.repository.rails_event_store

| Key     | Value |
| ------- | ----- |
| :stream | A [RubyEventStore::Stream](https://www.rubydoc.info/gems/ruby_event_store/RubyEventStore/Stream) that we delete |

```ruby
{
  stream: #<RubyEventStore::Stream:0x0000000106cbf578>
}
```


#### read.repository.rails_event_store

| Key            | Value |
| -------------- | ----- |
| :specification | A [RubyEventStore::SpecificationResult](https://www.rubydoc.info/gems/ruby_event_store/RubyEventStore/SpecificationResult) describing the query requested from event store |

```ruby
{
  specification: #<RubyEventStore::SpecificationResult:0x0000000113644d80>
}
```


#### count.repository.rails_event_store

| Key            | Value |
| -------------- | ----- |
| :specification | A [RubyEventStore::SpecificationResult](https://www.rubydoc.info/gems/ruby_event_store/RubyEventStore/SpecificationResult) describing the query requested from event store |

```ruby
{
  specification: #<RubyEventStore::SpecificationResult:0x0000000113644d80>
}
```


#### update_messages.repository.rails_event_store

| Key            | Value |
| -------------- | ----- |
| :messages      | An array of [RubyEventStore::Record](https://www.rubydoc.info/gems/ruby_event_store/RubyEventStore/Record) objects to replace existing ones of the same identifiers |

```ruby
{
  messages: [#<RubyEventStore::Record:0x0000000109e4ff98]
}
```


#### streams_of.repository.rails_event_store

| Key            | Value |
| -------------- | ----- |
| :event_id      | An identifier of the event used to query for streams it is present in |

```ruby
{
  event_id: "8cee1139-4f96-483a-a175-2b947283c3c7"
}
```


#### call.dispatcher.rails_event_store

| Key         | Value                                        |
| ----------- | -------------------------------------------- |
| :event      | An event which is being dispatched           |
| :subscriber | A subscriber to which event is dispatched to |

