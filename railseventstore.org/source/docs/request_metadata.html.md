# Logging request metadata

In Rails environment, every event is enhanced with the request metadata provided by `rack` server. This can help with debugging and building an audit log from events for the future use.

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

This can be configurable using `rails_event_store.request_metadata` field in your Rails configuration.

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
