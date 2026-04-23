# frozen_string_literal: true

require "dry/cli"
require_relative "base"
require_relative "../event_renderer"

module RubyEventStore
  module CLI
    module Commands
      class StreamEvents < Base
        include EventRenderer
        desc "Print events from a stream. Supports filtering by type, time, and position. Use --follow/-f to tail live."

        argument :stream_name, required: true, desc: "Stream name"
        option :limit, type: :integer, default: 50, desc: "Max number of events (default: 50)"
        option :format, default: "table", values: %w[table json], desc: "Output format"
        option :type, desc: "Filter by event type (class name)"
        option :after, desc: "Filter events newer than timestamp (ISO8601)"
        option :before, desc: "Filter events older than timestamp (ISO8601)"
        option :from, desc: "Start reading from event ID (exclusive)"
        option :follow, type: :boolean, default: false, aliases: ["-f"], desc: "Watch for new events (Ctrl+C to stop)"

        def call(stream_name:, limit:, format:, type: nil, after: nil, before: nil, from: nil, follow: false, **)
          events = build_reader(stream_name, type: type, after: after, before: before, from: from, limit: limit).to_a
          render(events, format: format)
          tail(stream_name, last_id: events.last&.event_id, type: type, format: format) if follow
        rescue Interrupt
          exit 0
        rescue => e
          warn e.message
          exit 1
        end

        private

        def build_reader(stream_name, type:, after:, before:, from:, limit:)
          reader = event_store.read.stream(stream_name)
          reader = reader.of_type(resolve_type(type))    if type
          reader = reader.newer_than(Time.parse(after))  if after
          reader = reader.older_than(Time.parse(before)) if before
          reader = reader.from(from)                     if from
          reader.limit(limit.to_i)
        end

        def tail(stream_name, last_id:, type:, format:)
          loop do
            sleep 1
            reader = event_store.read.stream(stream_name)
            reader = reader.of_type(resolve_type(type)) if type
            reader = reader.from(last_id)               if last_id
            events = reader.to_a
            next if events.empty?
            render(events, format: format)
            last_id = events.last.event_id
          end
        end

        def resolve_type(name)
          Object.const_get(name)
        rescue NameError
          raise "Unknown event type: #{name}"
        end

      end
    end
  end
end
