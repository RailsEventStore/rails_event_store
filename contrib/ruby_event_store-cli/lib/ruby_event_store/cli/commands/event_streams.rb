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
          streams = event_store.streams_of(event_id)

          if streams.empty?
            puts "(no streams — event not found or not linked to any stream)"
            return
          end

          streams.each { |stream| puts stream.name }
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
