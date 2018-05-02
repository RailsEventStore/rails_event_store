require 'spec_helper'
require 'rails_event_store/middleware'
require 'rack/test'
require 'rack/lint'
require 'support/test_application'

module RailsEventStore
  RSpec.describe Middleware do
    DummyEvent = Class.new(RailsEventStore::Event)

    specify 'works without event store instance' do
      request = ::Rack::MockRequest.new(Middleware.new(app))
      expect {request.get('/')}.not_to raise_error
    end

    specify 'sets domain events metadata for events published with global event store instance' do
      app.config.event_store = event_store
      app.config.x.rails_event_store = {
        request_metadata: -> env { {server_name: env['SERVER_NAME']} }
      }

      request = ::Rack::MockRequest.new(Middleware.new(app))
      request.get('/')

      event_store.read_all_streams_forward.map(&:metadata).each do |metadata|
        expect(metadata[:server_name]).to eq('example.org')
      end
    end

    def event_store
      @event_store ||= Client.new
    end

    def app
      TestApplication.tap do |app|
        app.routes.draw { root(to: ->(env) {event_store.publish_event(DummyEvent.new); [200, {}, ['']]}) }
      end
    end
  end
end


