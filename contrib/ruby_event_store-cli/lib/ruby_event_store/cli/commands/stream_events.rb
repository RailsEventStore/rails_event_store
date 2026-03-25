# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"
require_relative "../event_renderer"

module RubyEventStore
  module CLI
    module Commands
      class StreamEvents < Dry::CLI::Command
        include EventRenderer
        desc "List events in a stream"

        argument :stream_name, required: true, desc: "Stream name"
        option :limit, type: :integer, default: 50, desc: "Max number of events (default: 50)"
        option :format, default: "table", values: %w[table json], desc: "Output format"
        option :type, desc: "Filter by event type (class name)"
        option :after, desc: "Filter events newer than timestamp (ISO8601)"
        option :before, desc: "Filter events older than timestamp (ISO8601)"
        option :from, desc: "Start reading from event ID (exclusive)"

        def call(stream_name:, limit:, format:, type: nil, after: nil, before: nil, from: nil, **)
          event_store = EventStoreResolver.resolve
          reader = event_store.read.stream(stream_name)
          reader = reader.of_type(resolve_type(type)) if type
          reader = reader.newer_than(Time.parse(after)) if after
          reader = reader.older_than(Time.parse(before)) if before
          reader = reader.from(from) if from
          events = reader.limit(limit.to_i).to_a
          render(events, format: format)
        rescue => e
          warn e.message
          exit 1
        end

        private
      end
    end
  end
end
