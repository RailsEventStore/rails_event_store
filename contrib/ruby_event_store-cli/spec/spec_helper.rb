# frozen_string_literal: true

require "ruby_event_store"
require_relative "support/fake_configuration"

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.after { RubyEventStore::CLI::EventStoreResolver.event_store = nil }
end
