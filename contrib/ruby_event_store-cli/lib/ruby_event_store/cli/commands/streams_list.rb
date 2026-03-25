# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class StreamsList < Dry::CLI::Command
        desc "List streams"

        option :prefix, desc: "Filter streams by prefix"

        def call(prefix: nil, **)
          EventStoreResolver.resolve
          streams = fetch_streams(prefix: prefix)

          if streams.empty?
            puts "(no streams)"
          else
            streams.each { |s| puts s }
            puts "\n#{streams.size} stream(s)"
          end
        rescue => e
          warn e.message
          exit 1
        end

        private

        def fetch_streams(prefix: nil)
          streams = ::ActiveRecord::Base
            .connection
            .select_values("SELECT DISTINCT stream FROM event_store_events_in_streams ORDER BY stream")
            .reject { |s| s == "$all" }
          prefix ? streams.select { |s| s.start_with?(prefix) } : streams
        end
      end
    end
  end
end
