# frozen_string_literal: true

require "dry/cli"
require_relative "base"

module RubyEventStore
  module CLI
    module Commands
      class StreamShow < Base
        desc "Show event count, version, and first/last event for a stream"

        argument :stream_name, required: true, desc: "Stream name"

        def call(stream_name:, **)
          reader = event_store.read.stream(stream_name)
          count = reader.count

          if count.zero?
            puts "Stream:  #{stream_name}"
            puts "Events:  0"
            return
          end

          first = reader.first
          last = reader.last

          puts "Stream:  #{stream_name}"
          puts "Events:  #{count}"
          puts "Version: #{count - 1}"
          puts "First:   #{first.timestamp.iso8601(3)} (#{first.event_type})"
          puts "Last:    #{last.timestamp.iso8601(3)} (#{last.event_type})"
        rescue => e
          warn e.message
          exit 1
        end
      end
    end
  end
end
