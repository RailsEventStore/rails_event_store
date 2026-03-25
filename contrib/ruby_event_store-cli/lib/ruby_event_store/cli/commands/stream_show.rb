# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class StreamShow < Dry::CLI::Command
        desc "Show stream metadata"

        argument :stream_name, required: true, desc: "Stream name"

        def call(stream_name:, **)
          event_store = EventStoreResolver.resolve
          count = event_store.read.stream(stream_name).count
          first = event_store.read.stream(stream_name).first
          last  = event_store.read.stream(stream_name).last

          if count == 0
            puts "Stream: #{stream_name}"
            puts "Events: 0"
          else
            version = event_store.position_in_stream(last.event_id, stream_name)
            puts "Stream:  #{stream_name}"
            puts "Events:  #{count}"
            puts "Version: #{version}"
            puts "First:   #{first.timestamp.iso8601(3)} (#{first.event_type})"
            puts "Last:    #{last.timestamp.iso8601(3)} (#{last.event_type})"
          end
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
