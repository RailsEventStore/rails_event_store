# frozen_string_literal: true

require "dry/cli"
require_relative "commands/base"
require_relative "commands/stream_events"
require_relative "commands/stream_show"
require_relative "commands/event_show"
require_relative "commands/event_streams"
require_relative "commands/trace"
require_relative "commands/search"
require_relative "commands/stats"
require_relative "commands/watch"

module RubyEventStore
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "stream", Class.new(Dry::CLI::Command) {
        desc "Inspect a stream"
        def call(**) = warn "Usage: res stream SUBCOMMAND\n\nSubcommands: events, show\n\nRun `res stream --help` for details."
      }
      register "stream events", StreamEvents
      register "stream show", StreamShow

      register "event", Class.new(Dry::CLI::Command) {
        desc "Inspect an event"
        def call(**) = warn "Usage: res event SUBCOMMAND\n\nSubcommands: show, streams\n\nRun `res event --help` for details."
      }
      register "event show", EventShow
      register "event streams", EventStreams
      register "trace", Trace
      register "search", Search
      register "stats", Stats
      register "watch", Watch
    end
  end
end
