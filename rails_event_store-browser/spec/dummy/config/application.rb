require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require "rails_event_store/browser"

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.to_prepare do
      Rails.configuration.event_store = RailsEventStore::Client.new
    end
  end
end

