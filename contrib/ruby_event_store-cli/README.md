# ruby_event_store-cli

Command-line interface for inspecting and managing a RailsEventStore event store without needing `rails console`.

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
bundle exec res stream show --name Orders

# List events in a stream
bundle exec res stream events Orders
bundle exec res stream events Orders --limit 20
bundle exec res stream events Orders --format json
bundle exec res stream events Orders --type OrderPlaced
bundle exec res stream events Orders --after 2024-01-01

# Delete a stream
bundle exec res stream delete --stream-name Orders --dry-run
bundle exec res stream delete --stream-name Orders --force

# Bulk delete streams by prefix
bundle exec res stream delete --prefix Order- --dry-run
bundle exec res stream delete --prefix Order- --force
```

### Events

```bash
# Show a single event by ID
bundle exec res event show --event-id <uuid>

# Show all streams an event belongs to
bundle exec res event streams --event-id <uuid>
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
bundle exec res trace --correlation-id <uuid>
```

Output shows the causation tree — which event caused which.

### Replay

Replay events from a stream through a handler class:

```bash
# Dry run — shows count without calling handler
bundle exec res replay --stream Orders --handler OrderSummaryHandler --dry-run

# Run replay
bundle exec res replay --stream Orders --handler OrderSummaryHandler
```

The handler must be a class with a `.call(event)` class method:

```ruby
class OrderSummaryHandler
  def self.call(event)
    # process event
  end
end
```

### Stats

```bash
# Global stats: total events, stream count, top event types
bundle exec res stats

# Stats for a specific stream
bundle exec res stats --stream Orders
```

### Linking

```bash
# Link a single event to a stream
bundle exec res link --event-id <uuid> --stream target-stream

# Backfill: link all events of a type into a stream
bundle exec res link backfill --type OrderPlaced --stream $by_type_OrderPlaced --dry-run
bundle exec res link backfill --type OrderPlaced --stream $by_type_OrderPlaced

# Backfill from a specific source stream
bundle exec res link backfill --type OrderPlaced --stream archive --source-stream Orders
```

## Configuration

The CLI autodetects `config/environment.rb` in the current directory and loads the Rails environment. Run all commands from your Rails app root.

## License

MIT
