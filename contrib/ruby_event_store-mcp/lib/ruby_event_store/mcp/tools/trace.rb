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
          events = events_for(event_store, args.fetch("correlation_id"))
          return "(no events found for correlation ID #{args.fetch("correlation_id")})" if events.empty?
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
          roots.each do |e|
            lines << "#{e.event_type} [#{e.event_id}]"
            render_children(e, by_causation, "", lines)
          end
          lines.join("\n")
        end

        def root_events(events)
          event_ids = events.map(&:event_id)
          events.reject { |e| event_ids.include?(e.metadata[:causation_id]) }
        end

        def render_node(event, by_causation, prefix, lines)
          lines << "#{prefix}├── #{event.event_type} [#{event.event_id}]"
          render_children(event, by_causation, prefix + "│   ", lines)
        end

        def render_last_node(event, by_causation, prefix, lines)
          lines << "#{prefix}└── #{event.event_type} [#{event.event_id}]"
          render_children(event, by_causation, prefix + "    ", lines)
        end

        def render_children(event, by_causation, prefix, lines)
          children = by_causation[event.event_id] || []
          return if children.empty?
          *rest, last = children
          rest.each { |child| render_node(child, by_causation, prefix, lines) }
          render_last_node(last, by_causation, prefix, lines)
        end
      end
    end
  end
end
