# Logging request metadata

In Rails environment, every event is enhanced with the request metadata provided by `rack` server as long as you configure your event store instance in `config.event_store`. This can help with debugging and building an audit log from events for the future use.

## Setup

In order to enhance your events with metadata, you need to setup your client as described in [Installation](/docs/install).

## Defaults

With default configuration metadata is enhanced by:

* `:remote_ip` - IP of the HTTP client which issued the request.
* `:request_id` - An unique ID of the request.

This metadata is included **only for published events**. So creating a new event instance by hand won't add metadata to it:

```ruby
event = MyEvent.new(event_data)
event.metadata # empty, unless you provided your own data called 'metadata'.
```

If you publish an event, the special field called `metadata` will get filled in with request details:

```ruby
event_store.publish_event(MyEvent.new(data: {foo: 'bar'}))

my_event = event_store.read_all_events(RailsEventStore::GLOBAL_STREAM).last

my_event.metadata[:remote_ip] # your IP
my_event.metadata[:request_id] # unique ID
```

## Configuration

You can configure which metadata you'd like to catch. To do so, you need to provide a `lambda` which takes Rack environment and returns a metadata hash/object.

This can be configurable using `x.rails_event_store.request_metadata` field in your Rails configuration.

You should set it up globally (`config/application.rb`) or locally for each environment (`config/environments/test.rb`, `config/environments/development.rb`, `config/environments/production.rb`, ...). If you don't provide your own, the default implementation will be used.

Here is an example of such configuration (in `config/application.rb`), replicating the default behaviour:

```ruby
require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module YourAppName
  class Application < Rails::Application
    config.x.rails_event_store.request_metadata = -> (env) do
      request = ActionDispatch::Request.new(env)
      { remote_ip:  request.remote_ip,
        request_id: request.uuid,
      }
    end
    # ...
  end
end
```

You can read more about your possible options by reading [ActionDispatch::Request](http://api.rubyonrails.org/classes/ActionDispatch/Request.html) documentation.

## Passing your own metadata using `with_metadata` method

Apart from using the middleware, you can also set your metadata with `RubyEventStore::Client#with_metadata` method. You can specify custom metadata that will be added to all events published inside a block:

```ruby
event_store.with_metadata(remote_ip: '1.2.3.4', request_id: SecureRandom.uuid) do
  event_store.publish(MyEvent.new(data: {foo: 'bar'}))
end

my_event = event_store.read_all_events(RailsEventStore::GLOBAL_STREAM).last

my_event.metadata[:remote_ip] #=> '1.2.3.4'
my_event.metadata[:request_id] #=> unique ID
```

When using `with_metadata`, the `timestamp` is still added to the metadata unless you explicitly specify it on your own. Additionally, if you are also using the middleware & `request_metadata`, your metadata passed as `with_metadata` argument will be merged with the result of `rails_event_store.request_metadata` proc:

```ruby
event_store.with_metadata(causation_id: 1234567890) do
  event_store.publish(MyEvent.new(data: {foo: 'bar'}))
end

my_event = event_store.read_all_events(RailsEventStore::GLOBAL_STREAM).last
my_event.metadata[:remote_ip] #=> your IP from request metadata proc
my_event.metadata[:request_id #=> unique ID from request metadata proc
my_event.metadata[:causation_id] #=> 1234567890 from with_metadata argument
my_event.metadata[:timestamp] #=> a timestamp
```

You can nest multiple `with_metadata` calls, in such case the inmost argument is used:

```ruby
event_store.with_metadata(foo: 'bar') do
  event_store.with_metadata(foo: 'baz') do
    event_store.publish(MyEvent.new)
  end
end

my_event = event_store.read_all_events(RailsEventStore::GLOBAL_STREAM).last
my_event.metadata[:foo] #=> 'baz'
```

When you want to clear the metadata for some published events while having them set with `with_metadata`, you can just pass `nil` as an argument (please note that timestamp will still be included in the metadata hash):

```ruby
event_store.with_metadata(foo: 'bar') do
  event_store.with_metadata(nil) do
    event_store.publish(MyEvent.new)
  end
end

my_event = event_store.read_all_events(RailsEventStore::GLOBAL_STREAM).last
my_event.metadata[:foo] #=> nil
my_event.metadata[:timestamp] #=> a timestamp
```

