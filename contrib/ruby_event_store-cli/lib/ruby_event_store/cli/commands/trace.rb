# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class Trace < Dry::CLI::Command
        desc "Show causal chain for a correlation ID"

        argument :correlation_id, required: true, desc: "Correlation ID"

        def call(correlation_id:, **)
          event_store = EventStoreResolver.resolve
          stream_name = "$by_correlation_id_#{correlation_id}"
          events = event_store.read.stream(stream_name).to_a

          if events.empty?
            puts "(no events — correlation stream may not be set up or ID not found)"
            return
          end

          by_id = events.each_with_object({}) { |e, h| h[e.event_id] = e }
          children = Hash.new { |h, k| h[k] = [] }
          roots = []

          events.each do |event|
            causation_id = event.metadata[:causation_id]
            if causation_id && by_id.key?(causation_id)
              children[causation_id] << event
            else
              roots << event
            end
          end

          puts "Trace: #{correlation_id} (#{events.size} event(s))\n\n"
          roots.each { |e| print_tree(e, children, 0) }
        rescue => e
          warn e.message
          exit 1
        end

        private

        def print_tree(event, children, depth)
          indent = depth == 0 ? "" : ("  " * (depth - 1)) + "└─ "
          puts "#{indent}#{event.event_type}  #{event.timestamp.iso8601(3)}  #{event.event_id}"
          children[event.event_id].each { |child| print_tree(child, children, depth + 1) }
        end
      end
    end
  end
end
