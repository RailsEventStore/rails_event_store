# frozen_string_literal: true

require_relative "../read_events"

module RubyEventStore
  module MCP
    module Tools
      class Search
        def name
          "search"
        end

        def schema
          {
            name: name,
            description: "Search events across all streams by type, time range, or stream name",
            inputSchema: {
              type: "object",
              properties: {
                type: { type: "string", description: "Filter by event type class name" },
                after: { type: "string", description: "Filter events newer than timestamp (ISO8601)" },
                before: { type: "string", description: "Filter events older than timestamp (ISO8601)" },
                stream: { type: "string", description: "Limit search to a specific stream" },
                limit: { type: "integer", description: "Max number of events (default: 50)" }
              }
            }
          }
        end

        def call(event_store, args)
          specification = args["stream"] ? event_store.read.stream(args["stream"]) : event_store.read
          events = ReadEvents.of(
            specification,
            type: args["type"],
            after: args["after"],
            before: args["before"],
            limit: args.fetch("limit", 50)
          )
          return "(no events found)" if events.empty?
          format_events(events)
        end

        private

        def format_events(events)
          events.map { |e| "#{e.timestamp.iso8601(3)}  #{e.event_type}  [#{e.event_id}]" }.join("\n")
        end
      end
    end
  end
end
