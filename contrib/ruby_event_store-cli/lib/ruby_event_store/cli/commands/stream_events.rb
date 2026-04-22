# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class StreamEvents < Dry::CLI::Command
        desc "List events in a stream"

        argument :stream_name, required: true, desc: "Stream name"
        option :limit, type: :integer, default: 50, desc: "Max number of events (default: 50)"
        option :format, default: "table", values: %w[table json], desc: "Output format"
        option :type, desc: "Filter by event type (class name)"
        option :after, desc: "Filter events newer than timestamp (ISO8601)"
        option :before, desc: "Filter events older than timestamp (ISO8601)"
        option :from, desc: "Start reading from event ID (exclusive)"
        option :follow, type: :boolean, default: false, aliases: ["-f"], desc: "Watch for new events (Ctrl+C to stop)"

        def call(stream_name:, limit:, format:, type: nil, after: nil, before: nil, from: nil, follow: false, **)
          event_store = EventStoreResolver.resolve
          reader = event_store.read.stream(stream_name)
          reader = reader.of_type(resolve_type(type)) if type
          reader = reader.newer_than(Time.parse(after)) if after
          reader = reader.older_than(Time.parse(before)) if before
          reader = reader.from(from) if from
          events = reader.limit(limit.to_i).to_a
          render(events, format: format)

          if follow
            last_id = events.last&.event_id
            loop do
              sleep 1
              new_reader = event_store.read.stream(stream_name)
              new_reader = new_reader.of_type(resolve_type(type)) if type
              new_reader = new_reader.from(last_id) if last_id
              new_events = new_reader.to_a
              next if new_events.empty?
              render(new_events, format: format)
              last_id = new_events.last.event_id
            end
          end
        rescue Interrupt
          exit 0
        rescue => e
          warn e.message
          exit 1
        end

        private

        def resolve_type(name)
          Object.const_get(name)
        rescue NameError
          raise "Unknown event type: #{name}"
        end

        def render(events, format:)
          case format
          when "json" then render_json(events)
          when "table" then render_table(events)
          end
        end

        def render_json(events)
          require "json"
          puts JSON.pretty_generate(events.map { |e|
            { event_id: e.event_id, event_type: e.event_type, data: e.data,
              metadata: e.metadata.to_h, timestamp: e.timestamp.iso8601(3) }
          })
        end

        def render_table(events)
          return puts "(no events)" if events.empty?

          puts "%-36s  %-40s  %s" % ["EVENT ID", "TYPE", "TIMESTAMP"]
          puts "-" * 90
          events.each do |e|
            puts "%-36s  %-40s  %s" % [e.event_id, e.event_type, e.timestamp.iso8601(3)]
          end
          puts "\n#{events.size} event(s)"
        end
      end
    end
  end
end
