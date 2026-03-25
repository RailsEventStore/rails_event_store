# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class EventStreams < Dry::CLI::Command
        desc "List streams containing an event"

        argument :event_id, required: true, desc: "Event ID (UUID)"

        def call(event_id:, **)
          event_store = EventStoreResolver.resolve
          streams = event_store.streams_of(event_id).reject(&:global?).map(&:name)

          if streams.empty?
            warn "Event not found: #{event_id}"
            exit 1
          else
            streams.each { |s| puts s }
            puts "\n#{streams.size} stream(s)"
          end
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
