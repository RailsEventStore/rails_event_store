# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class Stats < Dry::CLI::Command
        desc "Show event store statistics"

        option :stream, desc: "Show stats for a specific stream"

        def call(stream: nil, **)
          event_store = EventStoreResolver.resolve
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
