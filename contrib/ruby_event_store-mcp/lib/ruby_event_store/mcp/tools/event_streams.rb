# frozen_string_literal: true

module RubyEventStore
  module MCP
    module Tools
      class EventStreams
        def name
          "event_streams"
        end

        def schema
          {
            name: name,
            description: "List all streams the event has been published or linked to",
            inputSchema: {
              type: "object",
              properties: {
                event_id: { type: "string", description: "Event ID (UUID)" }
              },
              required: ["event_id"]
            }
          }
        end

        def call(event_store, args)
          streams = event_store.streams_of(args["event_id"])
          return "(no streams — event not found or not linked to any stream)" if streams.empty?
          format_streams(streams)
        end

        private

        def format_streams(streams)
          streams.map(&:name).join("\n")
        end
      end
    end
  end
end
