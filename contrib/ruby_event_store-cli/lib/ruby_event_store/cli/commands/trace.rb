# frozen_string_literal: true

require "dry/cli"

module RubyEventStore
  module CLI
    module Commands
      class Trace < Dry::CLI::Command
        desc "Print the causation tree for all events sharing a correlation ID"

        argument :correlation_id, required: true, desc: "Correlation ID (UUID)"

        def call(correlation_id:, **)
          event_store = RubyEventStore::CLI::EVENT_STORE
          stream_name = "$by_correlation_id_#{correlation_id}"
          events = event_store.read.stream(stream_name).to_a

          if events.empty?
            puts "(no events found for correlation ID #{correlation_id})"
            return
          end

          by_causation = events.group_by { |e| e.metadata[:causation_id] }
          event_ids = events.map(&:event_id).to_set
          roots = events.select { |e| !event_ids.include?(e.metadata[:causation_id]) }

          roots.each { |e| print_tree(e, by_causation, "", true, roots.last == e) }
        rescue => e
          warn e.message
          exit 1
        end

        private

        def print_tree(event, by_causation, prefix, root, last)
          connector = root ? "" : (last ? "└── " : "├── ")
          puts "#{prefix}#{connector}#{event.event_type} [#{event.event_id}]"
          children = by_causation[event.event_id] || []
          child_prefix = root ? prefix : prefix + (last ? "    " : "│   ")
          children.each_with_index do |child, i|
            print_tree(child, by_causation, child_prefix, false, i == children.size - 1)
          end
        end
      end
    end
  end
end
