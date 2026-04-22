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

          if stream
            count = event_store.read.stream(stream).count
            puts "Stream:  #{stream}"
            puts "Events:  #{count}"
          else
            count = event_store.read.count
            puts "Events:  #{count}"
          end
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
