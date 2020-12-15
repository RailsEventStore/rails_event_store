# frozen_string_literal: true

require 'rspec'

module RubyEventStore
  module RSpec
    NotSupported = Class.new(StandardError)
  end
end

require "ruby_event_store/rspec/version"
require "ruby_event_store/rspec/be_event"
require "ruby_event_store/rspec/have_published"
require "ruby_event_store/rspec/have_applied"
require "ruby_event_store/rspec/publish"
require "ruby_event_store/rspec/apply"
require "ruby_event_store/rspec/matchers"

::RSpec.configure do |config|
  config.include ::RubyEventStore::RSpec::Matchers
end
