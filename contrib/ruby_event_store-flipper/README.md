# RubyEventStore::Flipper

Flipper integration for RubyEventStore.


## Installation

1. Ensure that your Flipper has instrumentation enabled
2. Enable RubyEventStore subscriber via `RubyEventStore::Flipper.enable(event_store_instance)`

Example:

```ruby
Flipper.configure do |config|
  config.default do
    # ... adapter configuration
    
    # Enable instrumentation in Flipper
    Flipper.new(adapter, instrumenter: ActiveSupport::Notifications)
  end
end

# Enable RubyEventStore instrumentation for Flipper
RubyEventStore::Flipper.enable(Rails.configuration.event_store)
```

## Customize stream pattern

By default, stream name for toggle `foobar` is `FeatureToggle$foobar`. You can customize it via `stream_pattern` argument:

```ruby
RubyEventStore::Flipper.enable(Rails.configuration.event_store, stream_pattern: ->(feature_name) { "feature_toggle-#{feature_name}" })
```

## Customize notifications component

Anything with the same API as `ActiveSupport::Notifications` is supported.

```ruby
RubyEventStore::Flipper.enable(Rails.configuration.event_store, instrumenter: AS::Notifications)
```
