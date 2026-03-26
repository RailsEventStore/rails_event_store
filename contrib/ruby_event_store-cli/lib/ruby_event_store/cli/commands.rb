# frozen_string_literal: true

require "dry/cli"
require_relative "commands/stream_events"
require_relative "commands/streams_list"
require_relative "commands/stream_show"
require_relative "commands/event_show"
require_relative "commands/event_streams"
require_relative "commands/trace"
require_relative "commands/search"
require_relative "commands/stats"
module RubyEventStore
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "stream", Class.new(Dry::CLI::Command) { desc "Inspect a stream" }
      register "stream events", StreamEvents
      register "stream show", StreamShow

      register "streams", Class.new(Dry::CLI::Command) { desc "List streams" }
      register "streams list", StreamsList

      register "event", Class.new(Dry::CLI::Command) { desc "Inspect an event" }
      register "event show", EventShow
      register "event streams", EventStreams
      register "trace", Trace
      register "search", Search
      register "stats", Stats
    end
  end
end
