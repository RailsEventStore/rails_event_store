# Custom Repository

## Installation with Bundler

By default RailsEventStore will use the ActiveRecord event repository. If you want to use another event repository without loading unnecessary ActiveRecord dependency, you'll need to do:

```ruby
gem 'rails_event_store', require: 'rails_event_store/all'
gem 'your_custom_repository'
```

After running `bundle install`, Rails Event Store should be ready to be used.
See custom repository README to learn how to setup its data store.

## Configure custom repository

```ruby
Rails.application.configure do
  config.to_prepare do
    Rails.configuration.event_store = RailsEventStore::Client.new(
      repository: YourCustomRepository.new
    )
  end
end
```

## Community event repositories

Those repositories were written by community members and are not guaranteed to be up to date with latest Rails event store.

* [rails\_event\_store\_mongoid](https://github.com/gottfrois/rails_event_store_mongoid) by [Pierre-Louis Gottfrois](https://github.com/gottfrois)

## Writing your own repository

If you want to write your own repository, we provide [a suite of tests that you can re-use](https://github.com/RailsEventStore/rails_event_store/blob/master/ruby_event_store/lib/ruby_event_store/spec/event_repository_lint.rb). Just [require](https://github.com/RailsEventStore/rails_event_store/blob/a6ffb8a535373023296222bbbb5dd6ee131a6792/rails_event_store_active_record/spec/event_repository_spec.rb#L3) and [include it](https://github.com/RailsEventStore/rails_event_store/blob/a6ffb8a535373023296222bbbb5dd6ee131a6792/rails_event_store_active_record/spec/event_repository_spec.rb#L26) in your repository spec. Make sure to meditate on which [exepcted_version option](/docs/expected_version/) you are going to support and how.

# Using RubyEventStore::InMemoryRepository for faster tests

RubyEventStore comes with `RubyEventStore::InMemoryRepository` that you can use in tests instead of the default one. `InMemoryRepository` does not persist events but offers the same characteristics as `RailsEventStoreActiveRecord::EventRepository`. It is tested with the same test suite and raises identical exceptions.

```ruby
RSpec.configure do |c|
  c.around(:each)
    Rails.configuration.event_store = RailsEventStore::Client.new(
      repository: RubyEventStore::InMemoryRepository.new()
    )
    # add subscribers here
  end
end
```

We don't recommend using `InMemoryRepository` in production even if you don't need to persist events because the repository keeps all published events in memory. This is acceptable in testing because you can throw the instance away for every test and garbage collector reclaims the memory. In production, your memory would keep growing until you restart the application server.

`InMemoryRepository` can take custom `mapper:` as an argument just like `RailsEventStoreActiveRecord::EventRepository`. [Read more on that](/docs/mapping_serialization/)