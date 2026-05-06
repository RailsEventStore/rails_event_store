# frozen_string_literal: true

module RubyEventStore
  module MCP
    module Tools
      class AggregateHistory
        def name
          "aggregate_history"
        end

        def schema
          {
            name: name,
            description: "Show the full event history of an aggregate instance",
            inputSchema: {
              type: "object",
              properties: {
                aggregate_type: { type: "string", description: "Aggregate class name (e.g. Order, Payment::Invoice)" },
                aggregate_id: { type: "string", description: "Aggregate ID (UUID or other identifier)" }
              },
              required: %w[aggregate_type aggregate_id]
            }
          }
        end

        def call(event_store, args)
          aggregate_type = args.fetch("aggregate_type")
          aggregate_id = args.fetch("aggregate_id")
          stream_name = "#{aggregate_type}$#{aggregate_id}"
          events = events(event_store, stream_name)
          render(stream_name, events)
        end

        private

        def events(event_store, stream_name)
          event_store.read.stream(stream_name).to_a
        end

        def render(stream_name, events)
          lines = ["Aggregate: #{stream_name}", "Events:    #{events.size}"]
          unless events.empty?
            lines << ""
            lines.concat(events.map { |e| "#{e.timestamp.iso8601(3)}  #{e.event_type}  [#{e.event_id}]" })
          end
          lines.join("\n")
        end
      end
    end
  end
end
