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

To be written soon :)