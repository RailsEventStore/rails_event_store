# frozen_string_literal: true

require "dry/cli"

module RubyEventStore
  module CLI
    module Commands
      class Stats < Dry::CLI::Command
        desc "Show total event count and unique event types. Use --stream for per-stream stats."

        option :stream, desc: "Show stats for a specific stream"

        def call(stream: nil, **)
          event_store = RubyEventStore::CLI::EVENT_STORE
          reader = stream ? event_store.read.stream(stream) : event_store.read

          puts "Stream:  #{stream}" if stream
          puts "Events:  #{reader.count}"

          types = reader.map(&:event_type).uniq.sort
          unless types.empty?
            puts "\nEvent types:"
            types.each { |t| puts "  #{t}" }
          end
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
