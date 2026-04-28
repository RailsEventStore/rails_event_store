# frozen_string_literal: true

module RubyEventStore
  module MCP
    module Tools
      class Trace
        def name
          "trace"
        end

        def schema
          {
            name: name,
            description: "Show the causation tree for all events sharing a correlation ID",
            inputSchema: {
              type: "object",
              properties: {
                correlation_id: { type: "string", description: "Correlation ID (UUID)" }
              },
              required: ["correlation_id"]
            }
          }
        end

        def call(event_store, args)
          events = events_for(event_store, args["correlation_id"])
          return "(no events found for correlation ID #{args["correlation_id"]})" if events.empty?
          build_tree(events)
        end

        private

        def events_for(event_store, correlation_id)
          event_store.read.stream("$by_correlation_id_#{correlation_id}").to_a
        end

        def build_tree(events)
          by_causation = events.group_by { |e| e.metadata[:causation_id] }
          roots = root_events(events)
          lines = []
          roots.each { |e| render_node(e, by_causation, "", true, roots.last == e, lines) }
          lines.join("\n")
        end

        def root_events(events)
          event_ids = events.map(&:event_id)
          events.reject { |e| event_ids.include?(e.metadata[:causation_id]) }
        end

        def render_node(event, by_causation, prefix, root, last, lines)
          connector = root ? "" : (last ? "└── " : "├── ")
          lines << "#{prefix + connector}#{event.event_type} [#{event.event_id}]"
          children = by_causation[event.event_id] || []
          child_prefix = root ? prefix : prefix + (last ? "    " : "│   ")
          children.each_with_index do |child, i|
            render_node(child, by_causation, child_prefix, false, i == children.size - 1, lines)
          end
        end
      end
    end
  end
end
