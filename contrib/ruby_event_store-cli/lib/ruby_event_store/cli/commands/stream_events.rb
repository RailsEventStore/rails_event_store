# frozen_string_literal: true

require "dry/cli"

module RubyEventStore
  module CLI
    module Commands
      class StreamEvents < Dry::CLI::Command
        desc "List events in a stream"

        argument :stream_name, required: true, desc: "Stream name"

        def call(stream_name:, **)
        end
      end
    end
  end
end
