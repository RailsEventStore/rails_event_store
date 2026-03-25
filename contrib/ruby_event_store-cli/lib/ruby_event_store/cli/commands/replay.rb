# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class Replay < Dry::CLI::Command
        desc "Replay events from a stream through a handler"

        option :stream,  required: true, desc: "Stream to replay"
        option :handler, required: true, desc: "Handler class name (must respond to .call(event))"
        option :dry_run, type: :boolean, default: false, desc: "Print event count without calling handler"

        def call(stream:, handler:, dry_run:, **)
          event_store = EventStoreResolver.resolve
          handler_class = resolve_handler(handler)
          events = event_store.read.stream(stream).to_a

          if events.empty?
            puts "(no events in stream '#{stream}')"
            return
          end

          if dry_run
            puts "Would replay #{events.size} event(s) through #{handler} from '#{stream}'"
            return
          end

          replayed = 0
          events.each do |event|
            handler_class.call(event)
            replayed += 1
          end

          puts "Replayed #{replayed} event(s) through #{handler} from '#{stream}'"
        rescue => e
          warn e.message
          exit 1
        end

        private

        def resolve_handler(name)
          klass = Object.const_get(name)
          unless klass.respond_to?(:call)
            raise "#{name} does not respond to .call — expected a handler with a .call(event) class method"
          end
          klass
        rescue NameError
          raise "Unknown handler: #{name}"
        end
      end
    end
  end
end
