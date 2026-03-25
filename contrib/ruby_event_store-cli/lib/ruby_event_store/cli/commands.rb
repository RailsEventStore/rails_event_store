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
require_relative "commands/stream_delete"
require_relative "commands/replay"
require_relative "commands/link"
require_relative "commands/link_backfill"

module RubyEventStore
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "stream events", StreamEvents
      register "stream show", StreamShow
      register "streams list", StreamsList
      register "event show", EventShow
      register "event streams", EventStreams
      register "trace", Trace
      register "search", Search
      register "stats", Stats
      register "stream delete", StreamDelete
      register "replay", Replay
      register "link", Link
      register "link backfill", LinkBackfill
    end
  end
end
