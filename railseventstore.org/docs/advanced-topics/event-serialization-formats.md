---
title: Event serialization formats
---

By default RailsEventStore will use `YAML` as a
serialization format. The reason is that `YAML` is available out of box
and can serialize and deserialize data types which are not easily
handled in other formats.

However, if you don't like `YAML` or you have different needs you can
choose to use different serializers or even replace mappers entirely.

## Configuring a different serializer

You can pass a different `serializer` as a dependency when [instantiating
the client](../getting-started/install).

Here is an example on how to configure RailsEventStore to serialize
events' `data` and `metadata` using `Marshal`.

```ruby
# config/environments/*.rb

Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new(
      repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: Marshal)
    )
  end
end
```

The provided `serializer` must respond to `load` and `dump`.

Serialization is needed not only when writing to and reading from storage, but also when scheduling events for background processing by async handlers:

```ruby
Rails.configuration.event_store = RailsEventStore::Client.new(
   dispatcher: RubyEventStore::ComposedDispatcher.new(
     RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: Marshal)),
     RubyEventStore::Dispatcher.new
   )
 )
```

```ruby
class SomeHandler < ActiveJob::Base
  include RailsEventStore::AsyncHandler.with(serializer: Marshal)

  def perform(event)
    # ...
  end
end
```

## Configuring for Postgres JSON/B data type

In Postgres database, you can store your events data and metadata in json or jsonb format.

To generate migration containing event table schemas run

```console
$ rails generate rails_event_store_active_record:migration --data-type=jsonb
```

Next, configure your event store client to the JSON client:

```ruby
Rails.configuration.event_store = RailsEventStore::JSONClient.new
```

If you need additional configuration beyond the included JSON client, continue from here. In your `RailsEventStore::Client` initialization, set repository serialization to ` RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)`

```ruby
# config/environments/*.rb

Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new(
      repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)
    )
  end
end
```

Using the `RubyEventStore::NULL` serializer will prevent the event store from serializing the event data and metadata. This is necessary because the Active Record will handle serialization before putting the data into the database. And will do otherwise when reading. Database itself expect data to be json already.

<div class="px-4 py-1 text-blue-600 bg-blue-100 border-l-4 border-blue-500" role="alert">
  <p class="text-base font-bold">Note that <code>JSON</code> converts symbols to strings. Ensure your code accounts for this when retrieving events.</p>
  
```ruby
JSON.load(JSON.dump({foo: :bar}))
=> {"foo"=>"bar"}
```

One way to approach this is to have your own event adapter, specific for the project you're working on.

```ruby
class MyEvent < RailsEventStore::Event
  def data
    ActiveSupport::HashWithIndifferentAccess.new(super)
  end
end

OrderPlaced = Class.new(MyEvent)
```


That shields you from data keys being transformed from symbols into strings. It doesn't do anything with data values associated to those keys.

```ruby
event_store.publish(OrderPlaced.new(event_id: 'e34fc19a-a92f-4c21-8932-a10f6fb2602b', data: { foo: :bar }))
event = event_store.read.event('e34fc19a-a92f-4c21-8932-a10f6fb2602b')

event.data[:foo]
\# => "bar"

event.data['foo']
\# => "bar"
```

Another way to achieve that could be define your own <a href="../advanced-topics/mappers#custom-mapper">custom mapper and transformation</a>

</div>
