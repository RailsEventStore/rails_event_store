# frozen_string_literal: true

require_relative "../read_events"

module RubyEventStore
  module MCP
    module Tools
      class StreamEvents
        def name
          "stream_events"
        end

        def schema
          {
            name: name,
            description: "List events in a stream with optional filters",
            inputSchema: {
              type: "object",
              properties: {
                stream_name: { type: "string", description: "Stream name" },
                limit: { type: "integer", description: "Max number of events (default: 20)" },
                type: { type: "string", description: "Filter by event type class name" },
                after: { type: "string", description: "Filter events newer than timestamp (ISO8601)" },
                before: { type: "string", description: "Filter events older than timestamp (ISO8601)" },
                from: { type: "string", description: "Start reading from event ID (exclusive)" }
              },
              required: ["stream_name"]
            }
          }
        end

        def call(event_store, args)
          events = ReadEvents.of(
            event_store.read.stream(args["stream_name"]),
            type: args["type"],
            after: args["after"],
            before: args["before"],
            from: args["from"],
            limit: args.fetch("limit", 20)
          )
          return "(no events)" if events.empty?
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
