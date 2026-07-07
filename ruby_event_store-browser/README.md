# RubyEventStore::Browser

Event browser companion application for RubyEventStore. Inspect stream contents and event details. Explore correlation and causation connections.

Find out more at [https://railseventstore.org](https://railseventstore.org/)

The browser is a Rails engine that renders its pages server-side with Hotwire.
Mount it in your Rails app and it reads from `Rails.configuration.event_store`:

```ruby
Rails.application.routes.draw do
  mount RailsEventStore::Browser => "/res" if Rails.env.development?
end
```

## Development

`make install test` installs dependencies and runs the specs (the UI is
covered by the Capybara feature specs in `spec/ui_spec.rb`). `make css` builds
the stylesheet from the templates with the standalone Tailwind CLI.
