# frozen_string_literal: true

require "dry/cli"
require_relative "base"

module RubyEventStore
  module CLI
    module Commands
      class EventStreams < Base
        desc "List all streams the event has been published or linked to"

        argument :event_id, required: true, desc: "Event ID (UUID)"

        def call(event_id:, **)
          streams = streams_of(event_id)
          streams.empty? ? puts("(no streams — event not found or not linked to any stream)") : streams.each { |stream| puts stream.name }
        rescue => e
          warn e.message
          exit 1
        end

        private

        def streams_of(event_id)
          event_store.streams_of(event_id)
        end
      end
    end
  end
end
