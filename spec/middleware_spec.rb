require 'spec_helper'
require 'rails_event_store/middleware'
require 'rack/lint'

module RailsEventStore
  RSpec.describe Middleware do
    specify 'lint' do
      request = ::Rack::MockRequest.new(::Rack::Lint.new(Middleware.new(
        ->(env) { [200, {}, ['Hello World']] },
        ->(env) { { kaka: 'dudu' } } )))

      expect { request.get('/') }.to_not raise_error
    end

    specify do
      request = ::Rack::MockRequest.new(Middleware.new(
        ->(env) { [200, {}, ['Hello World']] },
        ->(env) { { kaka: 'dudu' } } ))
      request.get('/')

      expect(Thread.current[:rails_event_store]).to be_nil
    end

    specify do
      request = ::Rack::MockRequest.new(Middleware.new(
        ->(env) { raise },
        ->(env) { { kaka: 'dudu' } } ))

      expect { request.get('/') }.to raise_error(RuntimeError)
      expect(Thread.current[:rails_event_store]).to be_nil
    end

    specify do
      request = ::Rack::MockRequest.new(Middleware.new(
        ->(env) { [200, {}, ['Hello World']] },
        ->(env) { raise } ))

      expect { request.get('/') }.to raise_error(RuntimeError)
      expect(Thread.current[:rails_event_store]).to be_nil
    end
  end
end

