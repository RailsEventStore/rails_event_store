# frozen_string_literal: true

module RubyEventStore
  module CLI
    module Commands
      class Link < Dry::CLI::Command
        desc "Link an existing event to a stream"

        argument :event_id, required: true, desc: "Event ID (UUID)"
        option :stream, required: true, desc: "Target stream name"
      end
    end
  end
end
