# Documentation changes

## [0.14.3](https://github.com/arkency/rails_event_store/releases/tag/v0.14.3)
  * No changes in documentation.

## [0.14.2](https://github.com/arkency/rails_event_store/releases/tag/v0.14.2)
  * No changes in documentation.

## [0.14.1](https://github.com/arkency/rails_event_store/releases/tag/v0.14.1)
  * Introduced: [Using custom event repository](repository.md)

## [0.14.0](https://github.com/arkency/rails_event_store/releases/tag/v0.14.0)
  * No changes in documentation, however [aggregate_root gem documentation](https://github.com/arkency/aggregate_root) has significant changes.

## [0.13.0](https://github.com/arkency/rails_event_store/releases/tag/v0.13.0)
  * Access to domain event data (and metadata) changed from:

  ```ruby
  festival_id = event.data.festival_id
  festival_id = event.metadata.request_id
  ```

  to:

  ```ruby
  festival_id = event.data[:festival_id]
  festival_id = event.metadata[:request_id]
  ```

  * Signatures of methods of `RailsEventStore::Client` might be changed.

## [0.12.1](https://github.com/arkency/rails_event_store/releases/tag/v0.12.1)
  * No changes in documentation.

## [0.12.0](https://github.com/arkency/rails_event_store/releases/tag/v0.12.0)
  * Publishing a domain event changed from:

  ```ruby
  stream_name = "order_1"
  event = OrderPlaced.new(...)
  client.publish_event(event, stream_name)
  ```

  to:

  ```ruby
  stream_name = "order_1"
  event = OrderPlaced.new(...)
  client.publish_event(event, stream_name: stream_name)
  ```

## [0.11.0](https://github.com/arkency/rails_event_store/releases/tag/v0.11.0)
  * Renamed `handle_event` to `call` in all event handlers.

## [0.10.0](https://github.com/arkency/rails_event_store/releases/tag/v0.10.0)
  * Creating a domain event changed from:

  ```ruby
  event = OrderPlaced.new(
              order_data: "sample",
              festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
          )
  ```

  to:

  ```ruby
  event = OrderPlaced.new(data: {
              order_data: "sample",
              festival_id: "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
      })
  ```

  * Renamed method `call` to `run` in projections.
  * Introduced: [Logging request metadata](request_metadata.md)
  * Introduced: Dynamic (one-shot) subscriptions (described in [Subscribing to events](subscribe.md))

## [0.9.0](https://github.com/arkency/rails_event_store/releases/tag/v0.9.0)
  * No changes in documentation.

## [0.8.0](https://github.com/arkency/rails_event_store/releases/tag/v0.8.0)
  * No changes in documentation.

## [0.7.0](https://github.com/arkency/rails_event_store/releases/tag/v0.7.0)
  * Introduced: [Making projections](projection.md)

## Previous releases

No history of changes in documentation for previous releases.
