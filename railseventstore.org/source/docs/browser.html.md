---
title: Browser
---

Browser is a web interface that allows you to inspect existing streams and their contents. You can use it for debugging purpose as well as a built-in audit log frontend.

![RES Browser](/images/localhost_3000_res_.png)

## Adding browser to the project

### Rails

Add this line to your application's Gemfile:

```ruby
gem 'ruby_event_store-browser'
```

Add this to your `routes.rb` to enable web interface in development:

```ruby
require 'ruby_event_store/browser/app'

Rails.application.routes.draw do
  mount RubyEventStore::Browser::App.for(
    event_store_locator: -> { Rails.configuration.event_store },
    host: 'http://localhost:3000',
    path: '/res'
  ) => '/res' if Rails.env.development?
end
```

It is assumed that you have _Rails Event Store_ configured at `Rails.configuration.event_store` (like we recommend in [docs](https://railseventstore.org/docs/install/)).

### Sinatra / Rack

Add this line to your application's Gemfile:

```ruby
gem 'ruby_event_store-browser'
gem 'sinatra'
```

Add this to your `config.ru` or wherever you mount your Rack apps to enable web interface. Check the appropriate environment variable (e.g. `ENV['RACK_ENV']`) to only mount the browser in the appropriate environment such as `development`.

There is a helper method on the Rack app to configure options `event_store_locator`, `host` and `path`.

```ruby
# e.g. Sinatra rackup file

require 'ruby_event_store/browser/app'

# Example RES client you might configure
event_store = RubyEventStore::Client.new(
  repository: RubyEventStore::InMemoryRepository.new
)

run RubyEventStore::Browser::App.for(
  event_store_locator: -> { event_store },
  host: 'http://localhost:4567'
)
```

Specify the `path` option if you are not mounting the browser at the root.

```ruby
# e.g. mounting the Rack app in Hanami

require 'ruby_event_store/browser/app'

run RubyEventStore::Browser::App.for(
  event_store_locator: -> { event_store },
  host: 'http://localhost:2300',
  path: '/res'
), at: '/res'
```

## Usage in production

### Rails

In a production environment you'll likely want to protect access to the browser. You can use the constraints feature of routing (in the `config/routes.rb` file) to accomplish this:

#### Devise

Allow any authenticated `User`:

```ruby
browser = ->(env) do
  request = Rack::Request.new(env)
  app = RubyEventStore::Browser::App.for(
    event_store_locator: -> { Rails.configuration.event_store },
    host: request.base_url,
    path: request.script_name
  )
  app.call(env)
end

Rails.application.routes.draw do
  authenticate :user do
    mount browser => "/res"
  end
end
```

Allow any authenticated `User` for whom `User#admin?` returns `true`:

```ruby
browser = ->(env) do
  request = Rack::Request.new(env)
  app = RubyEventStore::Browser::App.for(
    event_store_locator: -> { Rails.configuration.event_store },
    host: request.base_url,
    path: request.script_name
  )
  app.call(env)
end

Rails.application.routes.draw do
  authenticate :user, lambda { |u| u.admin? } do
    mount browser => "/res"
  end
end
```

### HTTP Basic Auth

Use HTTP Basic Auth with credentials set from `RES_BROWSER_USERNAME` and `RES_BROWSER_PASSWORD` environment variables:

```ruby
Rails.application.routes.draw do
  browser = Rack::Builder.new do
    use Rack::Auth::Basic do |username, password|
      # Protect against timing attacks:
      # - See https://codahale.com/a-lesson-in-timing-attacks/
      # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
      # - Use & (do not use &&) so that it doesn't short circuit.
      # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["RES_BROWSER_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["RES_BROWSER_PASSWORD"]))
    end

    map "/" do
      run ->(env) do
        request = Rack::Request.new(env)
        app = RubyEventStore::Browser::App.for(
          event_store_locator: -> { Rails.configuration.event_store },
          host: request.base_url,
          path: request.script_name
        )
        app.call(env)
      end
    end
  end

  mount browser, at: "/res"
end
```

### Sinatra

You can use Rack-based middleware such as HTTP Basic Auth (as illustrated in the Rails example above) to control access to the browser Rack app.
