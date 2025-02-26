# frozen_string_literal: true

require "action_controller/railtie"
require "rails_event_store/railtie"
require "securerandom"

class TestApplication < Rails::Application
  config.hosts = nil
  config.eager_load = false
  config.secret_key_base = SecureRandom.hex(16)
  config.event_store = RailsEventStore::Client.new
  config.active_support.to_time_preserves_timezone = :zone

  routes.append { mount RailsEventStore::Browser => "/res" }
  routes.default_url_options = { host: "example.org" }
end

TestApplication.initialize!
