require 'spec_helper'
require 'rails_event_store/middleware'
require 'rack/test'
require 'rack/lint'

module RailsEventStore
  RSpec.describe Middleware do

    let(:dummy_event_class) do
      Class.new(RailsEventStore::Event)
    end

    specify do
      event_store = Client.new

      request = ::Rack::MockRequest.new(Middleware.new(
        ->(env) { event_store.publish_event(dummy_event_class.new); [200, {}, ["Hello World from #{env["SERVER_NAME"]}"]] },
        ->(env) { { server_name: env['SERVER_NAME'] }}))
      request.get('/')

      event_store.read_events_forward(GLOBAL_STREAM).map(&:metadata).each do |metadata|
        expect(metadata.server_name).to  eq('example.org')
      end
    end
  end
end
