# frozen_string_literal: true

require "ruby_event_store"
require_relative "support/fake_configuration"

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include(Module.new do
    def stub_event_store(event_store)
      config = FakeConfiguration.new
      config.event_store = event_store
      stub_const("Rails", double("Rails", configuration: config))
    end
  end)
end
