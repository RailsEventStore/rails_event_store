# frozen_string_literal: true

require "dry/cli"
require_relative "commands/stream_events"
require_relative "commands/link"
require_relative "commands/link_backfill"

module RubyEventStore
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "stream events", StreamEvents
      register "link", Link
      register "link backfill", LinkBackfill
    end
  end
end
