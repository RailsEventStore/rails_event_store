require 'rack/test'
require 'action_controller/railtie'
require 'rails_event_store/railtie'
require 'securerandom'

class TestRails
  include Rack::Test::Methods

  attr_reader :app

  def initialize(test_config = {})
    @app = Class.new(::Rails::Application)
    @test_config = test_config
  end

  def call(action)
    @test_config
      .merge(
        { eager_load: false,
          secret_key_base: SecureRandom.hex
        })
      .each { |k, v| app.config.send("#{k}=", v) }
    app.initialize!
    app.routes.draw { root(to: ->(env) { action.(); [200, {}, ['']] }) }
    app.default_url_options = { host: 'example.com' }
    get('/')
  end
end

