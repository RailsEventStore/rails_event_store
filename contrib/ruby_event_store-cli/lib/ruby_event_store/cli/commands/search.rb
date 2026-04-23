# frozen_string_literal: true

require "dry/cli"
require_relative "base"
require_relative "../event_renderer"
require_relative "../read_events"

module RubyEventStore
  module CLI
    module Commands
      class Search < Base
        include EventRenderer

        desc "Search events across all streams by type, time range, or stream name"

        option :type, desc: "Filter by event type (class name)"
        option :after, desc: "Filter events newer than timestamp (ISO8601)"
        option :before, desc: "Filter events older than timestamp (ISO8601)"
        option :stream, desc: "Limit search to a specific stream"
        option :limit, type: :integer, default: 50, desc: "Max number of events (default: 50)"
        option :format, default: "table", values: %w[table json], desc: "Output format"

        def call(limit:, format:, type: nil, after: nil, before: nil, stream: nil, **)
          specification = stream ? event_store.read.stream(stream) : event_store.read
          events = ReadEvents.of(specification, type: type, after: after, before: before, limit: limit)
          render(events, format: format)
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
