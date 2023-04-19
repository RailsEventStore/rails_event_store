# RubyEventStore ROM Event Repository

![RubyEventStore ROM Event Repository](https://github.com/RailsEventStore/rails_event_store/workflows/ruby_event_store-rom/badge.svg)

A Ruby Object Model (ROM) implementation of events repository for [Ruby Event Store](https://github.com/RailsEventStore/rails_event_store).

This version of the ROM adapter supports [rom-sql](https://github.com/rom-rb/rom-sql) at this time. It is an alternative to the ActiveRecord `EventRepository` implementation used in `rails_event_store` gem.

[Read the docs to get started.](http://railseventstore.org/docs/repository/)

## Setup

### Rake tasks

Add to your `Rakefile`

```ruby
require "ruby_event_store/rom/rake_task"
```

### Database migration

A migration template can be found in [db/migrate/20210806000000_create_ruby_event_store_tables.rb](db/migrate/20210806000000_create_ruby_event_store_tables.rb).

You can choose the type of the `data` and `metadata` columns by using the `DATA_TYPE` environment variable:

```shell
rake db:migrate DATA_TYPE='text' # or
rake db:migrate DATA_TYPE='json' # or
rake db:migrate DATA_TYPE='jsonb'
```

### Application

```ruby
# config/initializers/ruby_event_store.rb

config = ROM::Configuration.new(:sql, ENV.fetch("DATABASE_URL"))
RES_ROM_CONTAINER = RubyEventStore::ROM.setup(config)

repository = RubyEventStore::ROM::EventRepository.new(
  rom: RES_ROM_CONTAINER,
  serializer: JSON # this setting is optional. Recommended when `data` and `metadata` are json(b) columns. 
)

event_store = RubyEventStore::Client.new(repository: repository)

event_store.subscribe_to_all_events(RubyEventStore::LinkByCausationId.new(event_store: event_store))
event_store.subscribe_to_all_events(RubyEventStore::LinkByCorrelationId.new(event_store: event_store))
event_store.subscribe_to_all_events(RubyEventStore::LinkByEventType.new(event_store: event_store))

EVENT_STORE = event_store
```
