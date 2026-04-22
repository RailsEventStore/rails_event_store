# ruby_event_store-cli

Command-line interface for inspecting a RubyEventStore event store without needing `rails console`.

## Installation

Add to your application's Gemfile:

```ruby
gem "ruby_event_store-cli"
```

The `res` executable will be available in your project. Run all commands from your Rails app root directory — the CLI autodetects `config/environment.rb` and loads your environment.

## Commands

### Stream

```bash
# List events in a stream (default: last 50)
bundle exec res stream events MyStream
bundle exec res stream events MyStream --limit 20
bundle exec res stream events MyStream --format json
bundle exec res stream events MyStream --type OrderPlaced
bundle exec res stream events MyStream --after 2024-01-01T00:00:00Z
bundle exec res stream events MyStream --before 2024-03-01T00:00:00Z
bundle exec res stream events MyStream --from <event_uuid>

# Follow a stream for new events (Ctrl+C to stop)
bundle exec res stream events MyStream --follow
bundle exec res stream events MyStream -f

# Show stream summary
bundle exec res stream show MyStream
```

### Event

```bash
# Show full event details (data, metadata, timestamps)
bundle exec res event show <uuid>

# List all streams an event belongs to
bundle exec res event streams <uuid>
```

### Search

Search events across all streams or within a specific one:

```bash
bundle exec res search --type OrderPlaced
bundle exec res search --type OrderPlaced --limit 100
bundle exec res search --type OrderPlaced --after 2024-01-01T00:00:00Z
bundle exec res search --stream Orders --type OrderPlaced
bundle exec res search --format json | jq '.[].data'
```

### Trace

Display the causal tree for a correlation ID — all events triggered by a single request, in order:

```bash
bundle exec res trace <correlation_id>
```

### Stats

```bash
# Total event count and unique event types
bundle exec res stats

# Stats for a specific stream
bundle exec res stats --stream Orders
```

### Watch

Live view of new events as they arrive, grouped by bounded context (namespace prefix of the class name):

```bash
# Watch all new events (Ctrl+C to stop)
bundle exec res watch

# Filter to specific namespace(s)
bundle exec res watch --namespace Ordering
bundle exec res watch --namespace Ordering,Payments

# Watch events from a point in time
bundle exec res watch --since 2024-01-15T10:00:00Z

# Adjust polling interval and max events shown per namespace
bundle exec res watch --interval 2 --limit 20
```

## License

MIT
