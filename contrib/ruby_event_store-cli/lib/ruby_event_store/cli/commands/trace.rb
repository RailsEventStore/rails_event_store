# frozen_string_literal: true

require "dry/cli"
require_relative "base"

module RubyEventStore
  module CLI
    module Commands
      class Trace < Base
        desc "Print the causation tree for all events sharing a correlation ID"

        argument :correlation_id, required: true, desc: "Correlation ID (UUID)"

        def call(correlation_id:, **)
          events = events_for(correlation_id)
          if events.empty?
            puts "(no events found for correlation ID #{correlation_id})"
            return
          end
          print_causation_tree(events)
        rescue => e
          warn e.message
          exit 1
        end

        private

        def events_for(correlation_id)
          event_store.read.stream("$by_correlation_id_#{correlation_id}").to_a
        end

        def print_causation_tree(events)
          causation = events.group_by { |e| e.metadata[:causation_id] }
          roots = root_events(events)
          roots.each { |e| print_tree(e, causation, "", true, roots.last == e) }
        end

        def root_events(events)
          event_ids = events.map(&:event_id).to_set
          events.reject { |e| event_ids.include?(e.metadata[:causation_id]) }
        end

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
