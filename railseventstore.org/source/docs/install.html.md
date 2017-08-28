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
