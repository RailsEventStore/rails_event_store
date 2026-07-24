# RubyEventStore::Browser::Swimlane

A [RubyEventStore browser](https://railseventstore.org) extension comparing several streams side by side: their events merged into one newest-first timeline table, one column per stream, with infinite scroll. An event linked into several compared streams renders once, as a link in each matching column. The timeline can be sorted along either axis of the bi-temporal model — created-at (default) or valid-at.

## Usage

```ruby
mount RubyEventStore::Browser::App.for(
  event_store_locator: -> { Rails.configuration.event_store },
  extensions: [RubyEventStore::Browser::Swimlane.new],
) => "/res"
```

A `Compare` link shows up on every stream page; the comparison itself lives under `/swimlane?streams[]=first&streams[]=second`.
