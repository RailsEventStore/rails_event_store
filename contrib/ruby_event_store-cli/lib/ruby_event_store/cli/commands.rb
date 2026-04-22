# frozen_string_literal: true

require "dry/cli"
require_relative "commands/stream_events"
require_relative "commands/stream_show"
require_relative "commands/event_show"
require_relative "commands/event_streams"
require_relative "commands/trace"
require_relative "commands/search"

module RubyEventStore
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "stream events", StreamEvents
      register "stream show", StreamShow
      register "event show", EventShow
      register "event streams", EventStreams
      register "trace", Trace
      register "search", Search
    end
  end
end
