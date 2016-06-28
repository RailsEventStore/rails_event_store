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

  RSpec.describe 'request details in event metadata' do
    specify 'no config' do
      event_store = Client.new

      TestRails.new.(->{ event_store.publish_event(DummyEvent.new) })

      expect(event_store.read_all_events(GLOBAL_STREAM))
        .to_not(be_empty)
      event_store.read_all_events(GLOBAL_STREAM)
        .map  { |event|    event.metadata }
        .each { |metadata| expect(metadata.keys).to(include(:remote_ip, :request_id)) }
    end

    specify 'custom config' do
      event_store = Client.new

      TestRails.new(rails_event_store: { request_metadata: ->(env) { { remote_ip: env['REMOTE_ADDR'] } } })
        .(->{ event_store.publish_event(DummyEvent.new) })

      expect(event_store.read_all_events(GLOBAL_STREAM))
        .to_not(be_empty)
      event_store.read_all_events(GLOBAL_STREAM)
        .map  { |event|    event.metadata }
        .each { |metadata| expect(metadata).to(include(remote_ip: '127.0.0.1')) }
    end
  end
end
