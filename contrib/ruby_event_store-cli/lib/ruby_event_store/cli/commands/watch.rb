# frozen_string_literal: true

require "dry/cli"
require_relative "base"

module RubyEventStore
  module CLI
    module Commands
      class Watch < Base
        desc "Watch new events live, grouped by bounded context"

        option :namespace, desc: "Filter by namespace(s), comma-separated (e.g. Ordering,Payments)"
        option :since, desc: "Watch events since timestamp (ISO8601, default: now)"
        option :limit, type: :integer, default: 50, desc: "Max events shown per namespace (default: 50)"
        option :interval, type: :integer, default: 1, desc: "Refresh interval in seconds (default: 1)"

        def call(namespace: nil, since: nil, limit:, interval:, **)
          started_at = since ? Time.parse(since) : Time.now
          namespaces = namespace&.split(",")&.map(&:strip)
          watch(since: started_at, namespaces: namespaces, limit: limit.to_i, interval: interval.to_i)
        rescue Interrupt
          show_cursor
          exit 0
        rescue => e
          show_cursor
          warn e.message
          exit 1
        end

        private

        def watch(since:, namespaces:, limit:, interval:)
          hide_cursor
          loop do
            events = grouped_events(since: since, namespaces: namespaces)
            render(events, limit: limit, since: since)
            sleep interval
          end
        end

        def grouped_events(since:, namespaces:)
          events = events_since(since)
          events = filter_by_namespaces(events, namespaces)
          group_by_namespace(events)
        end

        def events_since(since)
          event_store.read.newer_than(since).map do |e|
            { event_id: e.event_id, type: e.event_type, timestamp: e.timestamp }
          end
        end

        def filter_by_namespaces(events, namespaces)
          return events unless namespaces
          events.select { |e| namespaces.include?(namespace(e[:type])) }
        end

        def group_by_namespace(events)
          events.group_by { |e| namespace(e[:type]) }.sort
        end

        def render(grouped, limit:, since:)
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
          lines << dim("Watching since #{since.strftime("%H:%M:%S")} — Press Ctrl+C to exit")

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
