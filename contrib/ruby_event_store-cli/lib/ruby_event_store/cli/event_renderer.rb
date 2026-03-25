# frozen_string_literal: true

require "json"

module RubyEventStore
  module CLI
    module EventRenderer
      def render(events, format:)
        case format
        when "json" then render_json(events)
        when "table" then render_table(events)
        end
      end

      def render_json(events)
        puts JSON.pretty_generate(events.map { |e|
          { event_id: e.event_id, event_type: e.event_type, data: e.data,
            metadata: e.metadata.to_h, timestamp: e.timestamp.iso8601(3) }
        })
      end

      def render_table(events)
        return puts "(no events)" if events.empty?

        puts "%-36s  %-40s  %s" % ["EVENT ID", "TYPE", "TIMESTAMP"]
        puts "-" * 90
        events.each do |e|
          puts "%-36s  %-40s  %s" % [e.event_id, e.event_type, e.timestamp.iso8601(3)]
        end
        puts "\n#{events.size} event(s)"
      end

      def resolve_type(name)
        Object.const_get(name)
      rescue NameError
        raise "Unknown event type: #{name}"
      end
    end
  end
end
