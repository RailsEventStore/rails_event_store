# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class LinkBackfill < Dry::CLI::Command
        desc "Link all events of a given type to a stream"

        option :type, required: true, desc: "Event type (class name)"
        option :stream, required: true, desc: "Target stream name"
        option :source_stream, desc: "Read from this stream instead of global stream"
        option :dry_run, type: :boolean, default: false, desc: "Print count without linking"

        def call(type:, stream:, dry_run:, source_stream: nil, **)
          event_store = EventStoreResolver.resolve
          klass = resolve_type(type)
          linked = 0
          skipped = 0

          reader = source_stream ? event_store.read.stream(source_stream) : event_store.read
          reader.of_type(klass).each do |event|
            if dry_run
              linked += 1
            else
              begin
                event_store.link(event.event_id, stream_name: stream)
                linked += 1
              rescue RubyEventStore::EventDuplicatedInStream
                skipped += 1
              end
            end
          end

          if dry_run
            puts "Would link #{linked} event(s) to #{stream}"
          else
            puts "Linked #{linked} event(s) to #{stream}#{skipped > 0 ? ", skipped #{skipped} (already linked)" : ""}"
          end
        rescue => e
          warn e.message
          exit 1
        end

        private

        def resolve_type(name)
          Object.const_get(name)
        rescue NameError
          raise "Unknown event type: #{name}"
        end
      end
    end
  end
end
