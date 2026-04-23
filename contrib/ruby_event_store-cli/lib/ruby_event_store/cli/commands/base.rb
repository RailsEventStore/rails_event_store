# frozen_string_literal: true

require "dry/cli"

module RubyEventStore
  module CLI
    module Commands
      class Base < Dry::CLI::Command
        private

        def event_store
          Rails.configuration.event_store
        end
      end
    end
  end
end
