# frozen_string_literal: true

require "spec_helper"
require "rails_event_store/middleware"
require "support/test_application"

module RailsEventStore
  ::RSpec.describe Middleware do
    before { allow(Rails.application).to receive(:config).and_return(configuration) }

    specify "calls app within with_request_metadata block when app has configured the event store instance" do
      Rails.application.config.event_store = event_store = Client.new
      expect(event_store).to receive(:with_request_metadata).with(dummy_env).and_call_original
      expect(app).to receive(:call).with(dummy_env).and_call_original
      middleware = Middleware.new(app)
      expect(middleware.call(dummy_env)).to eq([204, {}, [""]])
    end

    specify "just calls the app when app has not configured the event store instance" do
      expect(app).to receive(:call).with(dummy_env).and_call_original
      middleware = Middleware.new(app)
      expect(middleware.call(dummy_env)).to eq([204, {}, [""]])
    end

    def dummy_env
      { "action_dispatch.request_id" => "dummy_id", "action_dispatch.remote_ip" => "dummy_ip" }
    end

    def configuration
      @configuration ||= FakeConfiguration.new
    end

    def app
      @app ||= ->(_) { [204, {}, [""]] }
    end
  end
end
