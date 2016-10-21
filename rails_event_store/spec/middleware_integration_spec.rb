require 'spec_helper'
require 'rails_event_store/middleware'
require 'rack/test'
require 'rack/lint'

module RailsEventStore
  RSpec.describe Middleware do
    DummyEvent = Class.new(RailsEventStore::Event)

    specify do
      event_store = Client.new

      request = ::Rack::MockRequest.new(Middleware.new(
        ->(env) { event_store.publish_event(DummyEvent.new); [200, {}, ["Hello World from #{env["SERVER_NAME"]}"]] },
        ->(env) { { server_name: env['SERVER_NAME'] }}))
      request.get('/')

      event_store.read_events_forward(GLOBAL_STREAM).map(&:metadata).each do |metadata|
        expect(metadata[:server_name]).to  eq('example.org')
      end
    end
  end
end


