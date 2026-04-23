# frozen_string_literal: true

require "dry/cli"
require_relative "base"

module RubyEventStore
  module CLI
    module Commands
      class Stats < Base
        desc "Show total event count and unique event types. Use --stream for per-stream stats."

        option :stream, desc: "Show stats for a specific stream"

        def call(stream: nil, **)
          specification = stream ? event_store.read.stream(stream) : event_store.read
          print_stats(specification, stream: stream)
        rescue => e
          warn e.message
          exit 1
        end

        private

        def print_stats(specification, stream:)
          puts "Stream:  #{stream}" if stream
          puts "Events:  #{specification.count}"
          print_event_types(specification)
        end

        def print_event_types(specification)
          types = specification.map(&:event_type).uniq.sort
          return if types.empty?
          puts "\nEvent types:"
          types.each { |t| puts "  #{t}" }
        end
      end
    end
  end
end
