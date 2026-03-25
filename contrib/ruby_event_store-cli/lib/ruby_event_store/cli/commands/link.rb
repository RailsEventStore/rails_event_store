# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class Link < Dry::CLI::Command
        desc "Link an existing event to a stream"

        argument :event_id, required: true, desc: "Event ID (UUID)"
        option :stream, required: true, desc: "Target stream name"

        def call(event_id:, stream:, **)
          event_store = EventStoreResolver.resolve
          event_store.link(event_id, stream_name: stream)
          puts "Linked #{event_id} to #{stream}"
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
