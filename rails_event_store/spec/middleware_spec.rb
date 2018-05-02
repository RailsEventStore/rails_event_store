require 'spec_helper'
require 'rails_event_store/middleware'
require 'support/test_application'

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
      TestApplication.tap do |app|
        app.routes.draw { root(to: ->(env) {[200, {}, ['']]}) }
      end
    end
  end
end

