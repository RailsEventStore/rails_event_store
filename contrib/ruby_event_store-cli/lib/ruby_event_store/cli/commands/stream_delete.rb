# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class StreamDelete < Dry::CLI::Command
        desc "Delete a stream (events remain in the store)"

        argument :stream_name, required: false, desc: "Stream name"
        option :prefix,  desc: "Delete all streams matching this prefix (requires --force)"
        option :dry_run, type: :boolean, default: false, desc: "Show what would be deleted without doing it"
        option :force,   type: :boolean, default: false, desc: "Skip confirmation prompt"

        def call(stream_name: nil, prefix: nil, dry_run: false, force: false, **)
          event_store = EventStoreResolver.resolve

          if prefix
            delete_by_prefix(event_store, prefix: prefix, dry_run: dry_run, force: force)
          elsif stream_name
            delete_single(event_store, stream_name: stream_name, dry_run: dry_run, force: force)
          else
            warn "Provide a stream name or --prefix"
            exit 1
          end
        rescue => e
          warn e.message
          exit 1
        end

        private

        def delete_single(event_store, stream_name:, dry_run:, force:)
          count = event_store.read.stream(stream_name).count

          if count == 0
            warn "Stream not found or already empty: #{stream_name}"
            exit 1
          end

          if dry_run
            puts "Would delete stream '#{stream_name}' (#{count} event link(s))"
            return
          end

          unless force
            $stderr.print "Delete stream '#{stream_name}' (#{count} event link(s))? [y/N] "
            answer = $stdin.gets.to_s.strip.downcase
            unless answer == "y"
              puts "Aborted."
              return
            end
          end

          event_store.delete_stream(stream_name)
          puts "Deleted stream '#{stream_name}'"
        end

        def delete_by_prefix(event_store, prefix:, dry_run:, force:)
          if prefix.strip.empty?
            warn "Prefix cannot be empty"
            exit 1
          end

          streams = fetch_streams_with_prefix(prefix)

          if streams.empty?
            warn "No streams found with prefix: #{prefix}"
            exit 1
          end

          if dry_run
            streams.each { |s| puts "Would delete '#{s}'" }
            puts "\nWould delete #{streams.size} stream(s)"
            return
          end

          unless force
            warn "--force is required for bulk deletion (#{streams.size} streams matching '#{prefix}*')"
            exit 1
          end

          streams.each do |stream_name|
            event_store.delete_stream(stream_name)
            puts "Deleted '#{stream_name}'"
          end
          puts "\nDeleted #{streams.size} stream(s)"
        end

        def fetch_streams_with_prefix(prefix)
          ::ActiveRecord::Base
            .connection
            .select_values(
              "SELECT DISTINCT stream FROM event_store_events_in_streams WHERE stream LIKE #{::ActiveRecord::Base.connection.quote("#{prefix}%")} AND stream != '$all' ORDER BY stream"
            )
        end
      end
    end
  end
end
