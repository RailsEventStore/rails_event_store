# frozen_string_literal: true

module RubyEventStore
  module MCP
    module Tools
      class Stats
        def name
          "stats"
        end

        def schema
          {
            name: name,
            description: "Show event count and unique event types. Use stream to get per-stream stats.",
            inputSchema: {
              type: "object",
              properties: {
                stream: { type: "string", description: "Show stats for a specific stream" }
              }
            }
          }
        end

        def call(event_store, args)
          specification = args["stream"] ? event_store.read.stream(args["stream"]) : event_store.read
          format_stats(specification, stream: args["stream"])
        end

        private

        def format_stats(specification, stream:)
          lines = []
          lines << "Stream:  #{stream}" if stream
          lines << "Events:  #{specification.count}"
          lines.concat(format_event_types(specification))
          lines.join("\n")
        end

        def format_event_types(specification)
          types = specification.map(&:event_type).uniq.sort
          return [] if types.empty?
          ["\nEvent types:"] + types.map { |t| "  #{t}" }
        end
      end
    end
  end
end
