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

        def call(stream_name:, limit:, format:, **)
          event_store = EventStoreResolver.resolve
          events = event_store.read.stream(stream_name).limit(limit.to_i).to_a
          render(events, format: format)
        rescue => e
          warn e.message
          exit 1
        end

        private

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
