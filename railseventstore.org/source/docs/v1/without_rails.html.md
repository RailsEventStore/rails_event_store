---
title: Using Ruby Event Store without Rails
---

ActiveRecord and [ROM](http://rom-rb.org/) ([Sequel](https://github.com/jeremyevans/sequel)) are supported SQL adapters out-of-the-box.

## Installation

Add to your `Gemfile`:

```ruby
source 'https://rubygems.org'

gem 'ruby_event_store'

# For ActiveRecord:
gem 'activerecord'
gem 'rails_event_store_active_record'

# For ROM/Sequel:
gem 'rom-sql'
gem 'ruby_event_store-rom', require: 'ruby_event_store/rom/sql'

# And one of:
gem 'sqlite3'
gem 'pg'
gem 'mysql2'
```

## Creating tables

**ActiveRecord:** As you are not using rails and its generators, please create required database tables which are equivalent to [what our migration would do](https://github.com/RailsEventStore/rails_event_store/blob/master/rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates/migration_template.rb).

### ROM/Sequel migrations

SQL schema migrations can be copied to your project using Rake tasks. (The ROM migrations use [Sequel](https://github.com/jeremyevans/sequel) under the hood.)

Add the tasks to your `Rakefile` to import them into your project:

```ruby
# In your project Rakefile
require 'ruby_event_store/rom/adapters/sql/rake_task'
```

Then run Rake tasks to get your database setup:

```shell
# Copies the migrations to your project (in db/migrate)s
bundle exec rake db:migrations:copy DATABASE_URL=postgres://localhost/database
# <= migration file created db/migrate/20180417201709_create_ruby_event_store_tables.rb

# Run the migrations in your project (in db/migrate)
bundle exec rake db:migrate DATABASE_URL=postgres://localhost/database
# <= db:migrate executed
```

By default, `data` and `metadata` are stored in text columns. You can specify the `DATA_TYPE` environment variable when copying migrations to use a JSON or JSONB column in Postgres.

```shell
bundle exec rake db:migrations:copy DATABASE_URL=postgres://localhost/database DATA_TYPE=jsonb
```

You can run `bundle exec rake -T` to get a list of all available tasks. You can also programmatically run migrations (see examples above).

NOTE: Make sure the database connection in your app doesn't try to connect and setup RES before the migrations have run.

## Usage

### ActiveRecord

```ruby
require 'active_record'
require 'rails_event_store_active_record'
require 'ruby_event_store'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

class OrderPlaced < RubyEventStore::Event
end

event_store = RubyEventStore::Client.new(
  repository: RailsEventStoreActiveRecord::EventRepository.new
)

event_store.publish(OrderPlaced.new(data: {
    order_id: 1,
    customer_id: 47271,
    amount: BigDecimal.new("20.00"),
  }),
  stream_name: "Order-1",
)
```

### ROM/Sequel setup

You simply need to configure your ROM container and then store it globally on `RubyEventStore::ROM.env` or pass it to the repository constructor.

```ruby
require 'ruby_event_store/rom/sql'

# Use the `setup` helper to configure repositories and mappers.
# Then store an Env instance to get access to the ROM container.
RubyEventStore::ROM.env = RubyEventStore::ROM.setup(:sql, ENV['DATABASE_URL'])

# Use the repository the same as with ActiveRecord
client = RubyEventStore::Client.new(
  repository: RubyEventStore::ROM::EventRepository.new
)
```

#### Advanced setup

You can use a specific ROM container per repository to customize it more extensively. This example illustrates how to get at the ROM configuration and even run the latest migrations.

```ruby
require 'ruby_event_store/rom/sql'

config = ROM::Configuration.new(:sql, ENV['DATABASE_URL'])

# Run migrations if you need to (optional)
config.default.run_migrations

# Use the `setup` helper to configure the ROM container
env = RubyEventStore::ROM.setup(config)

# Use the repository the same as with ActiveRecord
client = RubyEventStore::Client.new(
  repository: RubyEventStore::ROM::EventRepository.new(rom: env)
)

# P.S. Access the ROM container
container = env.container
```

This advanced option provides flexibility if you are using a separate database for RES or have other needs that require more granular configurations.

## Unavailable features

`rails_event_store` provides some features that `ruby_event_store` by design cannot:

- async handlers and ActiveJob integration

  You can implement and provide your [own dispatcher](https://github.com/RailsEventStore/rails_event_store/blob/a6ffb8a535373023296222bbbb5dd6ee131a6792/rails_event_store/lib/rails_event_store/active_job_dispatcher.rb#L47) which knows how to recognize and enqueue async handlers. Pass it [as a dependency](https://github.com/RailsEventStore/rails_event_store/blob/a6ffb8a535373023296222bbbb5dd6ee131a6792/rails_event_store/lib/rails_event_store/client.rb#L4) to `RubyEventStore::Client` constructor.

* Request metadata such as `remote_ip` and `request_id` won't be automatically filled in events' metadata.
