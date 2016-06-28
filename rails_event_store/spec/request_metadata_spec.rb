require 'spec_helper'
require 'action_controller/railtie'
require 'rails_event_store/railtie'
require 'rack/test'
require 'securerandom'


class TestRails
  include Rack::Test::Methods

  attr_reader :app

  def initialize
    @app = Class.new(::Rails::Application)
  end

  def call(action)
    app.config.secret_key_base = SecureRandom.hex
    app.config.eager_load = false
    app.initialize!
    app.routes.draw { root(to: ->(env) { action.(); [200, {}, ['']] }) }
    app.default_url_options = { host: 'example.com' }
    get('/')
  end
end

module RailsEventStore
  DummyEvent = Class.new(RailsEventStore::Event)

  RSpec.describe 'request details in event metadata' do
    specify do
      event_store = Client.new

      TestRails.new.(->{ event_store.publish_event(DummyEvent.new) })

      expect(event_store.read_all_events(GLOBAL_STREAM))
        .to_not(be_empty)
      event_store.read_all_events(GLOBAL_STREAM)
        .map  { |event|    event.metadata }
        .each { |metadata| expect(metadata).to(include(remote_ip: '127.0.0.1')) }
    end
  end
end
