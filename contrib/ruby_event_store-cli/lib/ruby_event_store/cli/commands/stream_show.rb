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
          specification = event_store.read.stream(stream_name)
          print_stream(stream_name, specification)
        rescue => e
          warn e.message
          exit 1
        end

        private

        def print_stream(stream_name, specification)
          count = specification.count
          puts "Stream:  #{stream_name}"
          puts "Events:  #{count}"
          return if count.zero?
          first = specification.first
          last = specification.last
          puts "Version: #{count - 1}"
          puts "First:   #{first.timestamp.iso8601(3)} (#{first.event_type})"
          puts "Last:    #{last.timestamp.iso8601(3)} (#{last.event_type})"
        end
      end
    end
  end
end
