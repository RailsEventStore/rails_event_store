require 'spec_helper'
require 'action_controller/railtie'
require 'rails_event_store/railtie'
require 'securerandom'
require 'rails_event_store/middleware'
require 'rack/lint'

module RailsEventStore
  RSpec.describe Middleware do
    specify 'calls app within with_metadata block when app has configured the event store instance' do
      expect(app).to receive(:call).with(dummy_env)
      middleware = Middleware.new(app)
      ::Rails.application.config.event_store = event_store = Client.new
      ::Rails.application.config.x = ::Rails::Application::Configuration::Custom.new
      expect(event_store).to receive(:with_metadata).with(request_id: 'dummy_id', remote_ip: 'dummy_ip').and_call_original
      middleware.call(dummy_env)
    end

    specify 'just calls the app when app has not configured the event store instance' do
      expect(app).to receive(:call).with(dummy_env)
      middleware = Middleware.new(app)
      middleware.call(dummy_env)
    end

    specify 'use config.rails_event_store.request_metadata' do
      middleware = Middleware.new(app)
      ::Rails.application.config.x.rails_event_store.request_metadata = kaka_dudu

      expect(middleware.request_metadata(dummy_env)).to eq({
        kaka: 'dudu'
      })
    end

    specify 'use config.rails_event_store.request_metadata is not callable' do
      middleware = Middleware.new(app)
      ::Rails.application.config.x.rails_event_store.request_metadata = {}

      expect(middleware.request_metadata(dummy_env)).to eq({
        request_id: 'dummy_id',
        remote_ip:  'dummy_ip'
      })
    end

    specify 'use config.rails_event_store.request_metadata is not set' do
      middleware = Middleware.new(app)
      ::Rails.application.config.x = ::Rails::Application::Configuration::Custom.new

      expect(middleware.request_metadata(dummy_env)).to eq({
        request_id: 'dummy_id',
        remote_ip:  'dummy_ip'
      })
    end

    def kaka_dudu
      ->(env) { { kaka: 'dudu' } }
    end

    def dummy_env
      {
        'action_dispatch.request_id' => 'dummy_id',
        'action_dispatch.remote_ip'  => 'dummy_ip'
      }
    end

    def app
      @app ||= Class.new(::Rails::Application) do
        def self.name
          "TestRails::Application"
        end
      end.tap do |app|
        app.config.eager_load = false
        app.config.secret_key_base = SecureRandom.hex
        app.initialize!
        app.routes.draw { root(to: ->(env) {[200, {}, ['']]}) }
        app.default_url_options = { host: 'example.com' }
      end
    end
  end
end

