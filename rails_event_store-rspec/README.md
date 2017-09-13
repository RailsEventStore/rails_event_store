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

The `be_event` matcher enables you to make expectations on a domain event. It exposes fluent interface.

```ruby
OrderPlaced  = Class.new(RailsEventStore::Event)
domain_event = OrderPlaced.new(
  data: {
    order_id: 42,
    net_value: BigDecimal.new("1999.0")
  },
  metadata: {
    remote_ip: '1.2.3.4'
  }
)

expect(domain_event)
  .to(be_an_event(OrderPlaced)
    .with_data(order_id: 42, net_value: BigDecimal.new("1999.0"))
    .with_metadata(remote_ip: '1.2.3.4'))
```

By default the behaviour of `with_data` and `with_metadata` is not strict, that is the expectation is met when all specified values for keys match. Additional data or metadata that is not specified to be expected does not change the outcome.

```ruby
domain_event = OrderPlaced.new(
  data: {
    order_id: 42,
    net_value: BigDecimal.new("1999.0")
  }
)

# this would pass even though data contains also net_value
expect(domain_event).to be_an_event(OrderPlaced).with_data(order_id: 42)
```

This matcher is both [composable](http://rspec.info/blog/2014/01/new-in-rspec-3-composable-matchers/) and accepting [built-in matchers](https://relishapp.com/rspec/rspec-expectations/v/3-6/docs/built-in-matchers) as a part of an expectation.

```ruby
expect(domain_event).to be_an_event(OrderPlaced).with_data(order_id: kind_of(Integer))

```

If you depend on matching the exact data or metadata, there's a `strict` modifier.

```ruby
domain_event = OrderPlaced.new(
  data: {
    order_id: 42,
    net_value: BigDecimal.new("1999.0")
  }
)

# this would fail as data contains unexpected net_value
expect(domain_event).to be_an_event(OrderPlaced).with_data(order_id: 42).strict
```

Mind that `strict` makes both `with_data` and `with_metadata` behave in a stricter way. If you need to mix both, i.e. strict data but non-strict metadata then consider composing matchers.

```ruby
expect(domain_event)
  .to(be_event(OrderPlaced).with_data(order_id: 42, net_value: BigDecimal.new("1999.0")).strict
    .and(an_event(OrderPlaced).with_metadata(timestamp: kind_of(Time)))
```

You may have noticed the same matcher being referenced as `be_event`, `be_an_event` and `an_event`. There's also just `event`. Use whichever reads better grammatically. 

### have_published

### have_appplied

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RailsEventStore/rails_event_store-rspec.
