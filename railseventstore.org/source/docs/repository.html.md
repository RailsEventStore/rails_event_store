## Installation with Bundler

By default RailsEventStore will use the Active Record event repository. If you want to use another event repository without loading unecessary Active Record dependency, you'll need to do:

```ruby
gem 'rails_event_store', require: false
gem 'your_custom_repository'
```

After running `bundle install`, Rails Event Store should be ready to be used.
See custom repository README to learn how to setup data store.

## Require custom repository

You need to require manually rails_event_store gem by doing:

```ruby
require 'rails_event_store/all'
```

And then define your custom event repository for RailsEventStore.

```ruby
RailsEventStore.event_repository = YourCustomRepository::EventRepository.new
```

This will be used every time you won't pass event repository as an argument
to `RailsEventStore::Client` initializer.


## Custom event repositories

- [rails\_event\_store\_mongoid](https://github.com/gottfrois/rails_event_store_mongoid) by [Pierre-Louis Gottfrois](https://github.com/gottfrois)
