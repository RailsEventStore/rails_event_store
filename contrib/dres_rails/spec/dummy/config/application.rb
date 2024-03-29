# frozen_string_literal: true

require_relative "boot"

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
# require "action_mailer/railtie"
# require "active_job/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"
# require "sprockets/railtie"

Bundler.require(*Rails.groups)
require "dres_rails"

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.generators { |g| g.test_framework :rspec }
  end
end
