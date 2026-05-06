# frozen_string_literal: true

module RubyEventStore
  module MCP
    module Tools
      class Recent
        DEFAULT_LIMIT = 20

        def name
          "recent"
        end

        def schema
          {
            name: name,
            description: "Show the most recent events across all streams",
            inputSchema: {
              type: "object",
              properties: {
                limit: { type: "integer", description: "Number of events to return (default: #{DEFAULT_LIMIT})" }
              },
              required: []
            }
          }
        end

        def call(event_store, args)
          limit = args.fetch("limit", DEFAULT_LIMIT).to_i
          events = event_store.read.limit(limit).backward.to_a
          return "(no events)" if events.empty?
          render(events)
        end

        private

        def render(events)
          events.map { |e| "#{e.timestamp.iso8601(3)}  #{e.event_type}  [#{e.event_id}]" }.join("\n")
        end
      end
    end
  end
end
