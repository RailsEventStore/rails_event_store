# ruby_event_store-cli

Command-line interface for inspecting a RailsEventStore event store without needing `rails console`.

## Installation

Add to your application's Gemfile:

```ruby
gem "ruby_event_store-cli"
```

The `res` executable will be available in your project. Run it from the Rails app root directory.

## Usage

### Streams

```bash
# List all streams
bundle exec res streams list

# Filter by prefix
bundle exec res streams list --prefix Order-

# Show stream summary (count, first/last event)
bundle exec res stream show MyStream

# List events in a stream
bundle exec res stream events MyStream
bundle exec res stream events MyStream --limit 20
bundle exec res stream events MyStream --format json
bundle exec res stream events MyStream --type OrderPlaced
bundle exec res stream events MyStream --after 2024-01-01

# Watch for new events in a stream (Ctrl+C to stop)
bundle exec res stream events MyStream --follow
bundle exec res stream events MyStream -f
```

### Events

```bash
# Show a single event by ID
bundle exec res event show <uuid>

# Show all streams an event belongs to
bundle exec res event streams <uuid>
```

### Search

```bash
# Search events by type across all streams
bundle exec res search --type OrderPlaced
bundle exec res search --type OrderPlaced --limit 50
bundle exec res search --type OrderPlaced --after 2024-01-01

# Search within a specific stream
bundle exec res search --type OrderPlaced --stream Orders
```

### Trace

Follow all events sharing the same correlation ID (e.g. everything triggered by a single request):

```bash
bundle exec res trace <correlation_id>
```

Output shows the causation tree — which event caused which.

### Stats

```bash
# Global stats: total events, stream count, top event types
bundle exec res stats

# Stats for a specific stream
bundle exec res stats --stream Orders
```

### Map

Derive your bounded context architecture from stream naming conventions — no code analysis needed:

```bash
bundle exec res map
```

Output shows bounded contexts, aggregates, process managers and read models inferred from stream names.

### Events (live view)

Watch new events as they arrive, grouped by bounded context:

```bash
# Watch all new events (default: follow mode)
bundle exec res events

# Filter by namespace
bundle exec res events --namespace Ordering
bundle exec res events --namespace Ordering,Payments

# One-shot dump (no follow)
bundle exec res events --no-follow

# Adjust refresh interval and events shown per namespace
bundle exec res events --interval 2 --limit 10
```

Press Ctrl+C to exit.

## Configuration

The CLI autodetects `config/environment.rb` in the current directory and loads the Rails environment. Run all commands from your Rails app root.

## License

MIT
