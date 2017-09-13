module RailsEventStore
  module RSpec
    NotSupported = Class.new(StandardError)
  end
end

require "rails_event_store/rspec/version"
require "rails_event_store/rspec/be_event"
require "rails_event_store/rspec/have_published"
require "rails_event_store/rspec/have_applied"
require "rails_event_store/rspec/matchers"

