# frozen_string_literal: true

require 'rspec'

module RailsEventStore
  module RSpec
    NotSupported = Class.new(StandardError)
  end
end

require "rails_event_store/rspec/version"
require "rails_event_store/rspec/be_event"
require "rails_event_store/rspec/have_published"
require "rails_event_store/rspec/have_applied"
require "rails_event_store/rspec/publish"
require "rails_event_store/rspec/apply"
require "rails_event_store/rspec/matchers"

::RSpec.configure do |config|
  config.include ::RailsEventStore::RSpec::Matchers
end
