# RubyEventStore ROM Event Repository

A ROM-based implementation of events repository for [Ruby Event Store](https://github.com/RailsEventStore/rails_event_store).

This version of the ROM adapter supports [rom-sql](https://github.com/rom-rb/rom-sql) at this time. It is an alternative to the ActiveRecord `EventRepository` implementation used in `rails_event_store` gem.

_Additonal backing stores via ROM are being tracked here: [#299](https://github.com/RailsEventStore/rails_event_store/issues/299)._

## Get started

The ROM repository class which implements the standard `RubyEventStore::EventRepository` API interface is: `RubyEventStore::ROM::EventRepository`

You simply need to configure your ROM container and then store it on `RubyEventStore::ROM.env` or pass it to the repository constructor.

### Basic setup

This is how to get ROM setup with relations and ROM repositories internally.

```ruby
config = ROM::Configuration.new(:sql, ENV['DATABASE_URL'])

# Run migrations if you need to
config.default.run_migrations

# Use the `setup` helper to configure the ROM container
container = RubyEventStore::ROM.setup(config)

# Store the ROM container globally
RubyEventStore::ROM.env = container

# Use the repository the same as with ActiveRecord
repo = RubyEventStore::ROM::EventRepository.new
```

Alternatively, use different ROM containers per repository:

```ruby
config = ROM::Configuration.new(:sql, ENV['DATABASE_URL'])

# Run migrations if you need to
config.default.run_migrations

# Use the `setup` helper to configure the ROM container
container = RubyEventStore::ROM.setup(config)

# Use the repository the same as with ActiveRecord
repo = RubyEventStore::ROM::EventRepository.new(rom: container)
```

The second option provides flexibility if you are using a separate database for RES or have other needs that require more granular configurations.
