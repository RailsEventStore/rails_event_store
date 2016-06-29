require 'spec_helper'
require 'action_controller/railtie'
require 'rails_event_store/railtie'
require 'rack/test'
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

module RailsEventStore
  DummyEvent = Class.new(RailsEventStore::Event)
  UUID_REGEX = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  RSpec.describe 'request details in event metadata' do
    specify 'no config' do
      event = nil

      TestRails.new.(->{ event = Event.new })

      expect(event.metadata[:remote_ip]).to  eq('127.0.0.1')
      expect(event.metadata[:request_id]).to match(UUID_REGEX)
    end

    specify 'custom config' do
      event = nil

      TestRails.new(rails_event_store: { request_metadata: ->(env) { { remote_ip: env['REMOTE_ADDR'] } } })
        .(->{ event = Event.new })

      expect(event.metadata[:remote_ip]).to eq('127.0.0.1')
    end
  end
end
