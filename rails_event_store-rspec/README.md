# RailsEventStore::RSpec

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_event_store-rspec'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_event_store-rspec

## Usage

Configure your rspec to include matchers in all examples first:

```ruby
RSpec.configure do |config|
  config.include ::RailsEventStore::RSpec::Matchers
end
```

You can as well choose to have RES matches in particular test file only:

```ruby
RSpec.describe MySubject do
  include ::RailsEventStore::RSpec::Matchers

  specify do
    # matchers available here
  end
end
```

### be_event

### have_published

### have_appplied

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RailsEventStore/rails_event_store-rspec.
