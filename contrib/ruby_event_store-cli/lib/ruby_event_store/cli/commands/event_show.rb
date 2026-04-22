# frozen_string_literal: true

require "dry/cli"
require "json"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class EventShow < Dry::CLI::Command
        desc "Print full event details including data, metadata, and timestamps"

        argument :event_id, required: true, desc: "Event ID (UUID)"

        def call(event_id:, **)
          event_store = EventStoreResolver.resolve
          event = event_store.read.event!(event_id)

          puts "Event ID:   #{event.event_id}"
          puts "Type:       #{event.event_type}"
          puts "Timestamp:  #{event.timestamp.iso8601(3)}"
          puts "Valid at:   #{event.valid_at.iso8601(3)}"
          puts "Data:       #{JSON.pretty_generate(event.data)}"
          puts "Metadata:   #{JSON.pretty_generate(event.metadata.to_h)}"
        rescue RubyEventStore::EventNotFound
          warn "Event not found: #{event_id}"
          exit 1
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
