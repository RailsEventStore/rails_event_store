---
title: Installation
sidebar_position: 2
---


## Quick setup

### New Rails application

If you're setting up a new Rails app, there is a fast way to begin with RailsEventStore using [template](https://railseventstore.org/new).

The template will:

- add `rails_event_store` to your `Gemfile`
- generate `config/initializers/rails_event_store.rb` with sane defaults and expose client under `Rails.configuration.event_store`
- pre–configure event browser to make it available under `/res` url in your app
- run bundler to install necessary dependencies
- generate migrations files and run them

```ruby
rails new -m https://railseventstore.org/new APP_NAME
```

<script id="asciicast-554171" src="https://asciinema.org/a/554171.js" async></script>

Obviously, you can specify all the [options](https://guides.rubyonrails.org/command_line.html#rails-new) which `rails new` takes, e.g. database you want to use:

```ruby
rails new -m https://railseventstore.org/new APP_NAME --database=postgresql
```

### Existing Rails application

The easiest way to install RailsEventStore and don't scratch your head is to use the [template](https://railseventstore.org/new).

Simply `cd` to your Rails application root directory and run:

```ruby
bin/rails app:template LOCATION=https://railseventstore.org/new
```

<script id="asciicast-554180" src="https://asciinema.org/a/554180.js" async></script>

The <a href="https://railseventstore.org/new">template</a> will:

- add `rails_event_store` to your `Gemfile`
- generate `config/initializers/rails_event_store.rb` with sane defaults and expose client under `Rails.configuration.event_store`
- pre–configure event browser to make it available under `/res` url in your app
- run bundler to install necessary dependencies
- generate migrations files and run them (respecting your database setup)

## Advanced setup

Steps described below are not required if you went with [quick setup](#quick-setup).

### Installation with Bundler

If your application dependencies happen to be managed by [Bundler](http://bundler.io/), please add the following line to your `Gemfile`:

```ruby
gem "rails_event_store"
```

After running `bundle install`, Rails Event Store should be ready to be used.

### Installation using RubyGems

You can also install this library using the `gem` command:

```
gem install rails_event_store
```

After requiring `rubygems` in your project you should be ready to use Rails Event Store.

### Setup data model

Use provided task to generate a table to store events in your database.
If you use `spring`, stop it first via `spring stop`.

#### Sqlite

```bash
bin/rails generate rails_event_store_active_record:migration
bin/rails db:migrate
```

#### MySQL

```bash
bin/rails generate rails_event_store_active_record:migration
bin/rails db:migrate
```

#### PostgreSQL

We find `jsonb` as the most reasonable data type for storing events. It is available since PostgreSQL 9.4.

```bash
bin/rails generate rails_event_store_active_record:migration --data-type=jsonb
bin/rails db:migrate
```

### Instantiate a client

```ruby
# config/environments/*.rb

Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new
    # add subscribers here
  end
end
```

or

```ruby
# config/application.rb
module YourAppName
  class Application < Rails::Application
    config.to_prepare do
      Rails.configuration.event_store = RailsEventStore::Client.new
      # add subscribers here
    end
  end
end
```

or

```ruby
# config/initializers/rails_event_store.rb
Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new
  # add subscribers here
end
```

Then in your application code you can reference it as:

```ruby
Rails.configuration.event_store
```

In Rails development mode when you change a registered class, it is reloaded, and a new class with same name is constructed. To keep `RailsEventStore` aware of changes in event classes, handler classes, and handler subscriptions use `to_prepare` [callback](http://api.rubyonrails.org/classes/Rails/Railtie/Configuration.html#method-i-to_prepare). It is executed before every code reload in development, and once in production.

#### Client for `jsonb` data type

If you decided to use `jsonb` data type for storing events, you can use a client that is optimized for this data type:

```ruby
Rails.configuration.event_store = RailsEventStore::JSONClient.new
```

It provides the same features and API as the default client, but it is optimized for `jsonb` data type, providing valid configuration for serialization and deserialization of events.


## Installation with Bundler

If your application dependencies happen to be managed by [Bundler](http://bundler.io/), please add the following line to your `Gemfile`:

```ruby
gem "rails_event_store"
```

After running `bundle install`, Rails Event Store should be ready to be used.

<div class="px-4 text-blue-600 bg-blue-100 border-l-4 border-blue-500" role="alert">
  <p class="text-base font-bold">Kickstarting new Rails application with RailsEventStore</p>
  <p class="inline-block text-base">If you're setting up a new Rails app, there is even a faster way to begin with RailsEventStore. The <a href="https://railseventstore.org/new">template</a> will install required gems, perform initial database migration, pre-configure event browser and more — <code class="bg-transparent">rails new -m https://railseventstore.org/new APP_NAME</code></p>

  <p class="inline-block text-base">
    Make sure to check generated <code class="bg-transparent">config/initializers/rails_event_store.rb</code> for initial configuration.
  </p>
</div>

## Installation using RubyGems

You can also install this library using the `gem` command:

```
gem install rails_event_store
```

After requiring `rubygems` in your project you should be ready to use Rails Event Store.

## Setup data model

Use provided task to generate a table to store events in your database.

```bash
spring stop # if you use spring
rails generate rails_event_store_active_record:migration
rake db:migrate
```

## Instantiate a client

```ruby
# config/environments/*.rb

Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new
    # add subscribers here
  end
end
```

or

```ruby
# config/application.rb
module YourAppName
  class Application < Rails::Application
    config.to_prepare do
      Rails.configuration.event_store = RailsEventStore::Client.new
      # add subscribers here
    end
  end
end
```

or

```ruby
# config/initializers/rails_event_store.rb
Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new
  # add subscribers here
end
```

Then in your application code you can reference it as:

```ruby
Rails.configuration.event_store
```

In Rails development mode when you change a registered class, it is reloaded, and a new class with same name is constructed. To keep `RailsEventStore` aware of changes in event classes, handler classes, and handler subscriptions use `to_prepare` [callback](http://api.rubyonrails.org/classes/Rails/Railtie/Configuration.html#method-i-to_prepare). It is executed before every code reload in development, and once in production.
