# frozen_string_literal: true

require "dry/cli"
require_relative "commands/stream_events"
require_relative "commands/stream_show"
require_relative "commands/event_show"

module RubyEventStore
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "stream events", StreamEvents
      register "stream show", StreamShow
      register "event show", EventShow
    end
  end
end
