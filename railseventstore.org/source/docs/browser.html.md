## Browser

Browser is a web interface that allows you to inspect existing streams and their contents. You can use it for debugging purpose as well as a built-in audit log frontend.

![RES Browser](/images/localhost_3000_res_.png)

## Adding browser to the project

Add this line to your application's Gemfile:

```ruby
gem 'rails_event_store-browser'
```

Add this to your `routes.rb` to enable web interface in development:

```ruby
Rails.application.routes.draw do
  mount RailsEventStore::Browser::Engine => "/res" if Rails.env.development?
end
```

## Usage in production

In a production environment you'll likely want to protect access to the browser. You can use the constraints feature of routing (in the `config/routes.rb` file) to accomplish this:

### Devise

Allow any authenticated `User`:

```ruby
Rails.application.routes.draw do
  authenticate :user do
    mount RailsEventStore::Browser::Engine => "/res"
  end
end
```

Allow any authenticated `User` for whom `User#admin?` returns `true`:

```ruby
Rails.application.routes.draw do
  authenticate :user, lambda { |u| u.admin? } do
    mount RailsEventStore::Browser::Engine => "/res"
  end
end
```

### Rails HTTP Basic Auth

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
      run RailsEventStore::Browser::Engine
    end
  end

  mount browser, at: "/res"
end
```

## Assumptions

* You don’t need pagination (just not yet implemented in this iteration, beware large streams)
* You have _Rails Event Store_ configured at `Rails.configuration.event_store` (like we recommend in [docs](http://railseventstore.org/docs/install/))
