---
title: Installation
---

## Installation with Bundler

If your application dependencies happen to be managed by [Bundler](http://bundler.io/), please add the following line to your `Gemfile`:

```ruby
gem "rails_event_store"
```

After running `bundle install`, Rails Event Store should be ready to be used.

<div class="bg-blue-100 border-l-4 border-blue-500 text-blue-600 px-4" role="alert">
  <p class="text-base font-bold">Kickstarting new Rails application with RailsEventStore</p>
  <p class="text-base inline-block">If you're setting up a new Rails app, there is even a faster way to begin with RailsEventStore. The <a href="https://railseventstore.org/new">template</a> will install required gems, perform initial database migration, pre-configure event browser and more — <code class="bg-transparent">rails new -m https://railseventstore.org/new APP_NAME</code></p>

  <p class="text-base inline-block">
    Make sure to check generated <code class="bg-transparent">config/initializers/rails_event_store.rb</code> for initial configuration.
  </p>
</div>

## Installation using RubyGems

You can also install this library using the `gem` command:

```bash
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

<div class="bg-blue-100 border-l-4 border-blue-500 text-blue-600 px-4" role="alert">
  <p class="text-base font-bold">Rails 5.0–5.1 with SQLite</p>
  <p class="text-base inline-block">If you're setting up a Rails 5.0 or Rails 5.1 app with sqlite database (i.e. for development)., you may encounter an issue when creating event_store_events_table — <code class="bg-transparent">ArgumentError: Index name 'sqlite_autoindex_event_store_events_1' on table 'event_store_events' already exists</code>.</p>

  <p class="text-base inline-block">
    This is a <a href="https://github.com/rails/rails/issues/33320">known</a> issue <a href="https://github.com/rails/rails/commit/7fae8e3f5d9a09a8bd024e09f2e953e3b48e4d53">fixed</a> in Rails 5.2. If you're going to stick with this configuration make sure to remove <code class="bg-transparent">t.index ["id"], name: "sqlite_autoindex_event_store_events_1", unique: true</code> line from <code class="bg-transparent">db/schema.rb</code> file.
  </p>
</div>

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
