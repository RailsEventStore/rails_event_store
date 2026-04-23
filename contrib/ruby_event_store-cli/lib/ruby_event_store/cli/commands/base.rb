# frozen_string_literal: true

require "dry/cli"

module RubyEventStore
  module CLI
    module Commands
      class Base < Dry::CLI::Command
        private

        def event_store
          CLI::EVENT_STORE
        end
      end
    end
  end
end
