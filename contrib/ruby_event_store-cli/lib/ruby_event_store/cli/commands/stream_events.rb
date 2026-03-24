# frozen_string_literal: true

module RubyEventStore
  module CLI
    module Commands
      class StreamEvents < Dry::CLI::Command
        desc "List events in a stream"

        argument :stream_name, required: true, desc: "Stream name"
      end
    end
  end
end
