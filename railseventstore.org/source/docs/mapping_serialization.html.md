# Events' serialization formats.

By default RailsEventStore will use `YAML` as a
serialization format. The reason is that `YAML` is available out of box
and can serialize and deserialize data types which are not easily
handled in other formats. As an example, `JSON` cannot out of box handle
deserializing dates. You get back `String` instead of a `Date`.

However, if you don't like `YAML` or you have different needs you can
choose to use different serializers (even whole mappers).

## Configuring a different serializer

You can pass a different `serializer` as a dependency when [instantiating
the client](/docs/install).

Here is an example on how to configure RailsEventStore to serialize
events' `data` and `metadata` using `JSON`.

```ruby
# config/environments/*.rb

Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new(
      repository: RailsEventStoreActiveRecord::EventRepository.new(
        mapper: RubyEventStore::Mappers::Default.new(
          serializer: JSON 
        )
      ) 
    )
  end
end
```

The provided `serializer` must respond to `load` and `dump`.

## Configuring a different mapper

Configuring a different mapper makes it possible to define events however you want and store in them in the database.
You no longer need to use `RubyEventStore::Event` (or `RailsEventStore::Event`) for events.
Any object can be used as events, provided you tell us how to map it to columns that we store in the DB.

Mapper needs to implement 3 methods:

* `event_to_serialized_record(domain_event)` - which takes an event and returns `RubyEventStore::SerializedRecord` with given attributes filled out:
  * `event_id` (String)
  * `data` (String)
  * `metadata` (String)
  * `event_type` (String)
* `serialized_record_to_event(record)` - which takes `RubyEventStore::SerializedRecord` and converts it to an instance of an event class that was stored.
* `add_metadata(domain_event, key, value)` - which knows how to (if possible) add automatically some metadata such as `request_ip`, `request_id` or `timestamp` to events.

```ruby
require 'msgpack'

class MyHashToMessagePackMapper
  def event_to_serialized_record(domain_event)
    # Use data (and metadata if applicable) fields
    # to store serialized representation
    # of your domain event 
    SerializedRecord.new(
      event_id:   domain_event.fetch('event_id'),
      metadata:   "",
      data:       domain_event.to_msg_pack,
      event_type: domain_event.fetch('event_type')
    )
  end

  # Deserialize proper object based on
  # event_type and data+metadata fields
  def serialized_record_to_event(record)
    MessagePack.unpack(record.data)
  end

  def add_metadata(event, key, value)
    event[key.to_s] = value
  end
end
```

Check out the code of our [default mapper](https://github.com/RailsEventStore/rails_event_store/blob/52d5104a8f47dab7f71c555d0185b58bc9c71c5a/ruby_event_store/lib/ruby_event_store/mappers/default.rb) and [protobuf mapper](https://github.com/RailsEventStore/rails_event_store/blob/52d5104a8f47dab7f71c555d0185b58bc9c71c5a/ruby_event_store/lib/ruby_event_store/mappers/protobuf.rb) on github for examples on how to implement mappers.


You can pass a different `mapper` as a dependency when [instantiating the client](/docs/install).

```ruby
# config/environments/*.rb

Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new(
      repository: RailsEventStoreActiveRecord::EventRepository.new(
        mapper: MyHashToMessagePackMapper.new
      )
    )
  end
end
```

Now you should be able to publish your events:

```ruby
Rails.configuration.event_store.publish_event({
  'event_id' => SecureRandom.uuid,
  'order_id' => 1,
  'event_type' => 'OrderPlaced',
  'order_amount' => BigDecimal.new('120.55'),
}, stream_name: 'Order$1')
```