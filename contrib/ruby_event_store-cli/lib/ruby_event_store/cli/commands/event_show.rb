# frozen_string_literal: true

require "dry/cli"
require "json"
require_relative "base"

module RubyEventStore
  module CLI
    module Commands
      class EventShow < Base
        desc "Print full event details including data, metadata, and timestamps"

        argument :event_id, required: true, desc: "Event ID (UUID)"

        def call(event_id:, **)
          event = event_store.read.event!(event_id)
          print_event(event)
        rescue RubyEventStore::EventNotFound
          warn "Event not found: #{event_id}"
          exit 1
        rescue => e
          warn e.message
          exit 1
        end

        private

        def print_event(event)
          puts "Event ID:   #{event.event_id}"
          puts "Type:       #{event.event_type}"
          puts "Timestamp:  #{event.timestamp.iso8601(3)}"
          puts "Valid at:   #{event.valid_at.iso8601(3)}"
          puts "Data:       #{JSON.pretty_generate(event.data)}"
          puts "Metadata:   #{JSON.pretty_generate(event.metadata.to_h)}"
        end
      end
    end
  end
end
