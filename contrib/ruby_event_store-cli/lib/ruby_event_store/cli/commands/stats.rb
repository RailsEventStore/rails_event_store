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
            stream_stats(event_store, stream)
          else
            global_stats(event_store)
          end
        rescue => e
          warn e.message
          exit 1
        end

        private

        def global_stats(event_store)
          total  = event_store.read.count
          streams = stream_count
          top    = top_event_types

          puts "Total events: #{total}"
          puts "Streams:      #{streams}"
          puts "\nTop event types:"
          top.each { |type, count| puts "  %-50s %d" % [type, count] }
        end

        def stream_stats(event_store, stream_name)
          count = event_store.read.stream(stream_name).count
          puts "Stream:  #{stream_name}"
          puts "Events:  #{count}"
          return if count == 0

          first   = event_store.read.stream(stream_name).first
          last    = event_store.read.stream(stream_name).last
          version = event_store.position_in_stream(last.event_id, stream_name)
          puts "Version: #{version}"
          puts "First:   #{first.timestamp.iso8601(3)} (#{first.event_type})"
          puts "Last:    #{last.timestamp.iso8601(3)} (#{last.event_type})"
        end

        def stream_count
          ::ActiveRecord::Base
            .connection
            .select_value("SELECT COUNT(DISTINCT stream) FROM event_store_events_in_streams WHERE stream != '$all'")
            .to_i
        end

        def top_event_types(limit: 10)
          ::ActiveRecord::Base
            .connection
            .select_rows(
              "SELECT event_type, COUNT(*) as cnt FROM event_store_events GROUP BY event_type ORDER BY cnt DESC LIMIT #{limit}"
            )
        end
      end
    end
  end
end
