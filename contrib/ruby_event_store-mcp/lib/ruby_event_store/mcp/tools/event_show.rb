# frozen_string_literal: true

require "json"

module RubyEventStore
  module MCP
    module Tools
      class EventShow
        def name
          "event_show"
        end

        def schema
          {
            name: name,
            description: "Show full event details including data, metadata, and timestamps",
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
          event = event_store.read.event!(args.fetch("event_id"))
          format_event(event)
        end

        private

        def format_event(event)
          [
            "Event ID:   #{event.event_id}",
            "Type:       #{event.event_type}",
            "Timestamp:  #{event.timestamp.iso8601(3)}",
            "Valid at:   #{event.valid_at.iso8601(3)}",
            "Data:       #{JSON.pretty_generate(event.data)}",
            "Metadata:   #{JSON.pretty_generate(event.metadata.to_h)}"
          ].join("\n")
        end
      end
    end
  end
end
