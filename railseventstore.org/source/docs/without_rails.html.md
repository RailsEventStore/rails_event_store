# Using Ruby Event Store without Rails

## Installation

Add to your `Gemfile`

```ruby
source 'https://rubygems.org'

gem 'activerecord'
gem 'ruby_event_store'
gem 'rails_event_store_active_record'

# And one of:
gem 'sqlite3'
gem 'pg'
gem 'mysql2',
```

## Creating tables

As you are not using rails and its generators, please create required database tables which are equivalent to [what our migration would do](https://github.com/RailsEventStore/rails_event_store/blob/master/rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates/migration_template.rb).

## Usage

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

## Unavailable features

`rails_event_store` provides some features that `ruby_event_store` by design cannot:

* async handlers and ActiveJob integration

    You can implement and provide your [own dispatcher](https://github.com/RailsEventStore/rails_event_store/blob/a6ffb8a535373023296222bbbb5dd6ee131a6792/rails_event_store/lib/rails_event_store/active_job_dispatcher.rb#L47) which knows how to recognize and enqueue async handlers. Pass it [as a dependency](https://github.com/RailsEventStore/rails_event_store/blob/a6ffb8a535373023296222bbbb5dd6ee131a6792/rails_event_store/lib/rails_event_store/client.rb#L4) to `RubyEventStore::Client` constructor.  
    
* Request metadata such as `remote_ip` and `request_id` won't be automatically filled in events' metadata.
