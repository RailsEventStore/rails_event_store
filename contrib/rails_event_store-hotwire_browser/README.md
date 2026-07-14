# RailsEventStore::HotwireBrowser

Event browser companion application for RailsEventStore, mounted as a Rails engine
and rendered server-side with Hotwire.

Inspect stream contents and event details. Explore correlation and causation
connections between events.

## Installation

```ruby
gem "rails_event_store-hotwire_browser"
```

## Usage

Mount the engine in your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount RailsEventStore::HotwireBrowser::Engine => "/res"
end
```

The engine reads events from `Rails.configuration.event_store`.

### Related streams

Provide a query to render related streams at the bottom of a stream view:

```ruby
config.x.rails_event_store_hotwire_browser_related_streams_query =
  ->(stream_name) { ... }
```

## Documentation

Full documentation is available at [railseventstore.org](https://railseventstore.org).
