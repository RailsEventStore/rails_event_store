# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"
require_relative "../event_renderer"

module RubyEventStore
  module CLI
    module Commands
      class Search < Dry::CLI::Command
        include EventRenderer

        desc "Search events across streams"

        option :type,   desc: "Filter by event type (class name)"
        option :stream, desc: "Limit to a specific stream (default: $by_type_* or global)"
        option :after,  desc: "Filter events newer than timestamp (ISO8601)"
        option :before, desc: "Filter events older than timestamp (ISO8601)"
        option :limit,  type: :integer, default: 50, desc: "Max number of events (default: 50)"
        option :format, default: "table", values: %w[table json], desc: "Output format"

        def call(type: nil, stream: nil, after: nil, before: nil, limit: 50, format: "table", **)
          event_store = EventStoreResolver.resolve
          reader = build_reader(event_store, type: type, stream: stream)
          reader = reader.newer_than(Time.parse(after)) if after
          reader = reader.older_than(Time.parse(before)) if before
          events = reader.limit(limit.to_i).to_a
          render(events, format: format)
        rescue => e
          warn e.message
          exit 1
        end

        private

        def build_reader(event_store, type:, stream:)
          reader = stream ? event_store.read.stream(stream) : event_store.read
          reader = reader.of_type(resolve_type(type)) if type
          reader
        end
      end
    end
  end
end
