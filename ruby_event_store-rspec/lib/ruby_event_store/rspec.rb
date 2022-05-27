# frozen_string_literal: true

require "rspec"

module RubyEventStore
  module RSpec
    NotSupported = Class.new(StandardError)
  end
end

require_relative "rspec/version"
require_relative "rspec/be_event"
require_relative "rspec/expected_collection"
require_relative "rspec/fetch_events"
require_relative "rspec/fetch_unpublished_events"
require_relative "rspec/match_events"
require_relative "rspec/have_published"
require_relative "rspec/have_applied"
require_relative "rspec/have_subscribed_to_events"
require_relative "rspec/publish"
require_relative "rspec/apply"
require_relative "rspec/crude_failure_message_formatter"
require_relative "rspec/step_by_step_failure_message_formatter"
require_relative "rspec/matchers"

module RubyEventStore
  module RSpec
    def self.default_formatter=(new_formatter)
      @@default_formatter = new_formatter
    end

    def self.default_formatter
      @@default_formatter ||= CrudeFailureMessageFormatter.new
    end
  end
end

::RSpec.configure { |config| config.include ::RubyEventStore::RSpec::Matchers }
