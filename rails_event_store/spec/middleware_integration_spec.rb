require 'spec_helper'
require 'rails_event_store/middleware'
require 'rack/test'
require 'rack/lint'
require 'support/test_application'

module RailsEventStore
  RSpec.describe Middleware do
    specify 'works without event store instance' do
      event_store = Client.new
      request = ::Rack::MockRequest.new(middleware)
      request.get('/')

      event_store.read.each do |event|
        expect(event.metadata.keys).to eq([:timestamp])
        expect(event.metadata[:timestamp]).to be_a(Time)
      end
    end

    specify 'sets domain events metadata for events published with global event store instance' do
      event_store = Client.new(
        request_metadata: -> env { {server_name: env['SERVER_NAME']} }
      )
      app.config.event_store = event_store

      request = ::Rack::MockRequest.new(middleware)
      request.get('/')

      event_store.read.each do |event|
        expect(event.metadata[:server_name]).to eq('example.org')
        expect(event.metadata[:timestamp]).to be_a(Time)
      end
    end

    def middleware
      ::Rack::Lint.new(Middleware.new(app))
    end

    def app
      TestApplication.tap do |app|
        app.routes.draw { root(to: ->(_env) {event_store.publish(DummyEvent.new); [200, {}, ['']]}) }
      end
    end
  end
end


