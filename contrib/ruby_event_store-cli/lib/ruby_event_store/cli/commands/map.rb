# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class Map < Dry::CLI::Command
        desc "Show bounded contexts, aggregates, process managers and read models"

        def call(**)
          EventStoreResolver.resolve
          streams = fetch_streams

          domains = Hash.new { |h, k| h[k] = Set.new }
          processes = Set.new
          read_models = Hash.new { |h, k| h[k] = Set.new }

          streams.each do |stream|
            next if stream.start_with?("$")

            parts = stream.split("$")
            type_part = parts[0]
            event_type = parts[2]

            namespace, aggregate = type_part.split("::", 2)

            next unless namespace && aggregate

            if namespace == "Processes"
              processes << aggregate
            elsif event_type
              read_models[type_part] << event_type
            else
              domains[namespace] << aggregate
            end
          end

          if domains.any?
            puts "Bounded Contexts & Aggregates:"
            domains.sort.each do |namespace, aggregates|
              puts "  #{namespace}"
              aggregates.sort.each { |a| puts "    #{a}" }
            end
            puts
          end

          if processes.any?
            puts "Process Managers:"
            processes.sort.each { |p| puts "  #{p}" }
            puts
          end

          if read_models.any?
            puts "Read Models:"
            read_models.keys.map { |k| k.split("::").first }.uniq.sort.each do |namespace|
              puts "  #{namespace}"
              read_models
                .select { |k, _| k.start_with?("#{namespace}::") }
                .each do |model, event_types|
                  puts "    #{model.split("::").last} ← #{event_types.sort.join(", ")}"
                end
            end
          end
        rescue => e
          warn e.message
          exit 1
        end

        private

        def fetch_streams
          ::ActiveRecord::Base
            .connection
            .select_values("SELECT DISTINCT stream FROM event_store_events_in_streams ORDER BY stream")
            .reject { |s| s == "$all" }
        end
      end
    end
  end
end
