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

  RSpec.describe Middleware do
    specify 'no config' do
      event_store = Client.new

      TestRails.new.(->{ event_store.publish_event(DummyEvent.new) })

      expect(event_store.read_all_events(GLOBAL_STREAM)).to_not be_empty
      event_store.read_all_events(GLOBAL_STREAM).map(&:metadata).each do |metadata|
          expect(metadata[:remote_ip]).to  eq('127.0.0.1')
          expect(metadata[:request_id]).to match(UUID_REGEX)
        end
    end
  end
end
