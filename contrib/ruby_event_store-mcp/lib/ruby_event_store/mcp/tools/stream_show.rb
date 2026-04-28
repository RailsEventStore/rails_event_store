# frozen_string_literal: true

module RubyEventStore
  module MCP
    module Tools
      class StreamShow
        def name
          "stream_show"
        end

        def schema
          {
            name: name,
            description: "Show event count, version, and first/last event for a stream",
            inputSchema: {
              type: "object",
              properties: {
                stream_name: { type: "string", description: "Stream name" }
              },
              required: ["stream_name"]
            }
          }
        end

        def call(event_store, args)
          stream_name = args.fetch("stream_name")
          specification = event_store.read.stream(stream_name)
          format_stream(stream_name, specification)
        end

        private

        def format_stream(stream_name, specification)
          count = specification.count
          lines = ["Stream:  #{stream_name}", "Events:  #{count}"]
          lines.concat(format_bounds(specification, count)) if count > 0
          lines.join("\n")
        end

        def format_bounds(specification, count)
          first = specification.first
          last = specification.last
          [
            "Version: #{count - 1}",
            "First:   #{first.timestamp.iso8601(3)} (#{first.event_type})",
            "Last:    #{last.timestamp.iso8601(3)} (#{last.event_type})"
          ]
        end
      end
    end
  end
end
