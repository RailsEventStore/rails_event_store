# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class StreamDelete < Dry::CLI::Command
        desc "Delete a stream (events remain in the store)"

        argument :stream_name, required: true, desc: "Stream name"
        option :dry_run, type: :boolean, default: false, desc: "Show what would be deleted without doing it"
        option :force,   type: :boolean, default: false, desc: "Skip confirmation prompt"

        def call(stream_name:, dry_run:, force:, **)
          event_store = EventStoreResolver.resolve
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
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
