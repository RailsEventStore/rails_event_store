# frozen_string_literal: true

require "dry/cli"
require_relative "commands/stream_events"
require_relative "commands/stream_show"
require_relative "commands/event_show"
require_relative "commands/event_streams"
require_relative "commands/trace"

module RubyEventStore
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "stream events", StreamEvents
      register "stream show", StreamShow
      register "event show", EventShow
      register "event streams", EventStreams
      register "trace", Trace
    end
  end
end
