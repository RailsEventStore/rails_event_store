# frozen_string_literal: true

require "dry/cli"
require_relative "commands/stream_events"

module RubyEventStore
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "stream events", StreamEvents
    end
  end
end
