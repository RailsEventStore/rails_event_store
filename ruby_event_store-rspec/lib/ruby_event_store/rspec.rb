# frozen_string_literal: true

require 'rspec'

module RubyEventStore
  module RSpec
    NotSupported = Class.new(StandardError)
  end
end

require_relative "rspec/version"
require_relative "rspec/be_event"
require_relative "rspec/have_published"
require_relative "rspec/have_applied"
require_relative "rspec/have_subscribed_to_events"
require_relative "rspec/publish"
require_relative "rspec/apply"
require_relative "rspec/matchers"

::RSpec.configure do |config|
  config.include ::RubyEventStore::RSpec::Matchers
end
