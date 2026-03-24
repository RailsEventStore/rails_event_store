# frozen_string_literal: true

require "dry/cli"
require_relative "commands/stream_events"
require_relative "commands/link"

module RubyEventStore
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "stream events", StreamEvents
      register "link", Link
    end
  end
end
