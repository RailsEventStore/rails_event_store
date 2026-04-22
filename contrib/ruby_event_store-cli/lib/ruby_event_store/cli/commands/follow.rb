# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class Follow < Dry::CLI::Command
        desc "Watch new events live, grouped by bounded context"

        option :namespace, desc: "Filter by namespace(s), comma-separated (e.g. Ordering,Payments)"
        option :since, desc: "Watch events since timestamp (ISO8601, default: now)"
        option :limit, type: :integer, default: 5, desc: "Max events shown per namespace (default: 5)"
        option :interval, type: :integer, default: 1, desc: "Refresh interval in seconds (default: 1)"
        option :follow, type: :boolean, default: true, desc: "Watch for new events (default: true, use --no-follow for one-shot)"

        def call(namespace: nil, since: nil, limit:, interval:, follow:, **)
          event_store = EventStoreResolver.resolve
          started_at = since ? Time.parse(since) : Time.now
          namespaces = namespace&.split(",")&.map(&:strip)

          if follow
            hide_cursor
            loop do
              render(event_store, limit: limit.to_i, since: started_at, namespaces: namespaces, follow: true)
              sleep interval.to_i
            end
          else
            render(event_store, limit: limit.to_i, since: started_at, namespaces: namespaces, follow: false)
          end
        rescue Interrupt
          show_cursor
          exit 0
        rescue => e
          show_cursor
          warn e.message
          exit 1
        end

        private

        def render(event_store, limit:, since:, namespaces:, follow:)
          events = event_store.read.newer_than(since).map do |e|
            { event_id: e.event_id, type: e.event_type, timestamp: e.timestamp }
          end
          events = events.select { |e| namespaces.include?(namespace(e[:type])) } if namespaces
          grouped = events.group_by { |e| namespace(e[:type]) }.sort

          lines = []
          if grouped.empty?
            lines << dim("No events yet — waiting since #{since.strftime("%H:%M:%S")}")
          else
            grouped.each do |ns, ns_events|
              lines << bold("#{ns} (#{ns_events.size} events)")
              ns_events.last(limit).each do |e|
                lines << "  #{pad(short_type(e[:type]), 30)} #{e[:timestamp].strftime("%H:%M:%S")}  #{e[:event_id]}"
              end
              lines << ""
            end
          end
          lines << dim("Watching since #{since.strftime("%H:%M:%S")} — Press Ctrl+C to exit") if follow

          clear_screen
          puts lines.join("\n")
        end

        def namespace(type)
          type.include?("::") ? type.split("::").first : "Other"
        end

        def short_type(type)
          type.split("::").last
        end

        def pad(str, width)
          str.ljust(width)[0, width]
        end

        def clear_screen
          system("clear")
        end

        def hide_cursor
          print "\e[?25l"
        end

        def show_cursor
          print "\e[?25h"
        end

        def bold(str)
          "\e[1m#{str}\e[0m"
        end

        def dim(str)
          "\e[2m#{str}\e[0m"
        end
      end
    end
  end
end
