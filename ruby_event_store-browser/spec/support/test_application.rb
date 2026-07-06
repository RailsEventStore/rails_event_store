# frozen_string_literal: true

require "action_controller/railtie"
require "ruby_event_store/browser"
require "securerandom"

class TestApplication < Rails::Application
  config.root = __dir__
  config.hosts = nil
  config.eager_load = false
  config.secret_key_base = SecureRandom.hex(16)
  config.event_store = RubyEventStore::Client.new

  routes.append { mount RubyEventStore::Browser::Engine => "/" }
  routes.default_url_options = { host: "www.example.com" }
end

TestApplication.initialize!
