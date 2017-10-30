## Installation with Bundler

If your application dependencies happen to be managed by [Bundler](http://bundler.io/), please add the following line to your `Gemfile`:

```ruby
gem "rails_event_store"
```

After running `bundle install`, Rails Event Store should be ready to be used.

## Installation using RubyGems

You can also install this library using the `gem` command:

```bash
gem install rails_event_store
```

After requiring `rubygems` in your project you should be ready to use Rails Event Store.

## Setup data model

Use provided task to generate a table to store events in your database.

```bash
rails generate rails_event_store_active_record:migration
rake db:migrate
```

## Working with Rails development mode

In Rails development mode when you change a registered class, it is reloaded, and a new class with same name is constructed.
To keep `RailsEventStore` aware of changes in event classes, handler classes, and handler subscriptions use [`to_prepare`](http://api.rubyonrails.org/classes/Rails/Railtie/Configuration.html#method-i-to_prepare) callback.
It is executed before every code reload in development, and once in production.

```ruby
# config/environments/*.rb

Rails.application.configure do
  config.to_prepare do
    config.event_store = RailsEventStore::Client.new
  end
end
```

or

```ruby
# config/application.rb
module YourAppName
  class Application < Rails::Application
    config.to_prepare do
      config.event_store = RailsEventStore::Client.new
    end
  end
end
```

Then in your application code you can reference it as:

```ruby
Rails.configuration.event_store
```

