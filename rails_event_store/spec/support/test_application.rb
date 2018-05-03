require 'action_controller/railtie'
require 'rails_event_store/railtie'
require 'securerandom'

class TestApplication < Rails::Application
  config.eager_load = false
  config.secret_key_base = SecureRandom.hex(16)
  initialize!
  routes.default_url_options = { host: 'example.org' }
end
