---
title: Using Ruby Event Store without Rails
sidebar_label: Ruby Event Store - without Rails
---

ActiveRecord and [ROM](http://rom-rb.org/) ([Sequel](https://github.com/jeremyevans/sequel)) are supported SQL adapters
out-of-the-box.



## RubyEventStore::ActiveRecord
`RubyEventStore::ActiveRecord` enables you to efficiently set up Ruby Event Store with your favorite web framework
different than Rails. It provides a rake task to generate the migration file to create database tables
required by Ruby Event Store. The rake task also enables you to perform database migrations.

### Installation

Add following gems into your `Gemfile`

```ruby
# Gemfile
source "https://rubygems.org"

gem "ruby_event_store-active_record"
gem "rake" # required to run rake tasks exposed by RubyEventStore::ActiveRecord
```

You'll also need SQL adapter of your choice. We support PostgreSQL, MySQL and SQLite3.

```ruby
# Gemfile
# ...
gem "sqlite3"
gem "pg"
gem "mysql2"
```

Now you can install the gems by running `bundle install`

Add following line to your Rakefile

```ruby
# Rakefile
require "ruby_event_store/active_record/tasks"
```

You can now run `bundle exec rake -T` to see the list of available tasks.
You'll notice that there are a lot of familiar tasks from Rails. That's because `RubyEventStore::ActiveRecord` depends
on `ActiveRecord::Tasks::DatabaseTasks` to perform database operations.

### Creating migration file

To create database migration file required by Ruby Event Store run


```bash
DATA_TYPE=jsonb DATABASE_URL=postgres://localhost/somedb_development bundle exec rake db:migrations:copy
```

In the example above we use `jsonb` data type for storing event data. You can use also use `json` or `binary` data type
if you're using PostgreSQL. For MySQL and SQLite3 we only support `binary` data type.

By default the migration file is created in `db/migrate` directory.
Your migration path might differ from that. You can specify the path to the migration file by setting `MIGRATION_PATH` environment variable.

```bash
MIGRATION_PATH=database/migrations
```

The command to create database migration file with custom migration path would look like this

```bash
DATA_TYPE=jsonb MIGRATION_PATH=database/migrations bundle exec rake db:migrations:copy
```

### Performing database migration

To perform database migration run

```bash
DATABASE_URL=postgres://localhost/somedb_development bundle exec rake db:migrate
```

`DATABASE_URL` is used to establish connection to your database and read the config.

**We don't read the database config from config/database.yml**

By default migration files are read from the `db/migrate` directory. If your application is structured in a different way,
you'll have to provide the path to your database directory and path to the directory containing migration files.

Path to the database directory can be provided through `DATABASE_DIR` environment variable.

```bash
DATABASE_DIR=path/to/database/directory
```
```

Similarly, path to the directory containing migration files can be provided through `MIGRATION_DIR` environment variable.

```bash
MIGRATION_DIR=path/to/migration/directory
```

**We expect the path to be relative.**

The command to run migration with all the environment variables set would look like this

```bash
MIGRATION_DIR=migration_path DATABASE_DIR=db_dir DATABASE_URL=postgres://localhost/somedb_development bundle exec rake db:migrate
```


## ROM/Sequel

### Installation

Add following gems into your `Gemfile`

```ruby
source "https://rubygems.org"

gem "ruby_event_store"
gem "rom-sql"
gem "ruby_event_store-rom", require: "ruby_event_store/rom/sql"
```

You'll also need an SQL adapter. We support PostgreSQL, MySQL and SQLite3.

```ruby
# Choose one of SQL adapters
gem "sqlite3"
gem "pg"
gem "mysql2"
```

Perform gem install.

### Migrations

SQL schema migrations can be copied to your project using Rake tasks. (The ROM migrations use [Sequel](https://github.com/jeremyevans/sequel) under the hood.)

Add the tasks to your `Rakefile` to import them into your project:

```ruby
# In your project Rakefile
require "ruby_event_store/rom/rake_task"
```

Then run Rake tasks to get your database setup:

```shell
# Copies the migrations to your project (in db/migrate)
bundle exec rake db:migrations:copy DATABASE_URL=postgres://localhost/database
# <= migration file created db/migrate/20180417201709_create_ruby_event_store_tables.rb

# Runs the migrations and creates the tables
bundle exec rake db:migrate DATABASE_URL=postgres://localhost/database
# <= db:migrate executed
```

By default, `data` and `metadata` are stored in text columns. You can specify the `DATA_TYPE` environment variable when copying migrations to use a JSON or JSONB column in Postgres.

```shell
bundle exec rake db:migrations:copy DATABASE_URL=postgres://localhost/database DATA_TYPE=jsonb
```

You can run `bundle exec rake -T` to get a list of all available tasks. You can also programmatically run migrations (see examples above).

NOTE: Make sure the database connection in your app doesn't try to connect and setup RES before the migrations have run.

### Configuration

You simply need to configure your ROM container and then store it globally on `RubyEventStore::ROM.env` or pass it to the repository constructor.

```ruby
require "ruby_event_store/rom/sql"

# Use the `setup` helper to configure repositories and mappers.
# Then store an Env instance to get access to the ROM container.
RubyEventStore::ROM.env = RubyEventStore::ROM.setup(:sql, ENV["DATABASE_URL"])

# Use the repository the same as with ActiveRecord
client = RubyEventStore::Client.new(repository: RubyEventStore::ROM::EventRepository.new)
```

#### Advanced setup

You can use a specific ROM container per repository to customize it more extensively. This example illustrates how to get at the ROM configuration and even run the latest migrations.

```ruby
require "ruby_event_store/rom/sql"

config = ROM::Configuration.new(:sql, ENV["DATABASE_URL"])

# Run migrations if you need to (optional)
config.default.run_migrations

# Use the `setup` helper to configure the ROM container
env = RubyEventStore::ROM.setup(config)

# Use the repository the same as with ActiveRecord
client = RubyEventStore::Client.new(repository: RubyEventStore::ROM::EventRepository.new(rom: env))

# P.S. Access the ROM container
container = env.container
```

This advanced option provides flexibility if you are using a separate database for RES or have other needs that require more granular configurations.

## Unavailable features

`rails_event_store` provides some features that `ruby_event_store` by design cannot:

- async handlers and ActiveJob integration

  You can implement and provide your [own dispatcher](https://github.com/RailsEventStore/rails_event_store/blob/a6ffb8a535373023296222bbbb5dd6ee131a6792/rails_event_store/lib/rails_event_store/active_job_dispatcher.rb#L47) which knows how to recognize and enqueue async handlers. Pass it [as a dependency](https://github.com/RailsEventStore/rails_event_store/blob/a6ffb8a535373023296222bbbb5dd6ee131a6792/rails_event_store/lib/rails_event_store/client.rb#L4) to `RubyEventStore::Client` constructor.

* Request metadata such as `remote_ip` and `request_id` won't be automatically filled in events' metadata.
