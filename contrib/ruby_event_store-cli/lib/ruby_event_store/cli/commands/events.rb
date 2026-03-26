# frozen_string_literal: true

require "dry/cli"
require_relative "../event_store_resolver"

module RubyEventStore
  module CLI
    module Commands
      class Events < Dry::CLI::Command
        desc "Watch new events live, grouped by bounded context"

        option :namespace, desc: "Filter by namespace(s), comma-separated (e.g. Ordering,Payments)"
        option :limit, type: :integer, default: 5, desc: "Max events shown per namespace (default: 5)"
        option :interval, type: :integer, default: 1, desc: "Refresh interval in seconds (default: 1)"
        option :follow, type: :boolean, default: true, desc: "Watch for new events (default: true, use --no-follow for one-shot)"

        def call(namespace: nil, limit:, interval:, follow:, **)
          EventStoreResolver.resolve
          started_at = Time.now
          namespaces = namespace&.split(",")&.map(&:strip)

          if follow
            hide_cursor
            loop do
              render(limit: limit.to_i, since: started_at, namespaces: namespaces, follow: true)
              sleep interval.to_i
            end
          else
            render(limit: limit.to_i, since: started_at, namespaces: namespaces, follow: false)
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

        def render(limit:, since:, namespaces:, follow:)
          rows = fetch_events(since: since)
          rows = rows.select { |r| namespaces.include?(namespace(r[:type])) } if namespaces
          grouped = rows.group_by { |r| namespace(r[:type]) }.sort

          lines = []
          if grouped.empty?
            lines << dim("No events yet — waiting since #{since.strftime("%H:%M:%S")}")
          else
            grouped.each do |ns, events|
              lines << bold("#{ns} (#{events.size} events)")
              events.last(limit).each do |e|
                lines << "  #{pad(short_type(e[:type]), 30)} #{e[:timestamp].strftime("%H:%M:%S")}  #{e[:event_id]}"
              end
              lines << ""
            end
          end
          lines << dim("Watching since #{since.strftime("%H:%M:%S")} — Press Ctrl+C to exit") if follow

          clear_screen
          puts lines.join("\n")
        end

        def fetch_events(since:)
          ::ActiveRecord::Base
            .connection
            .select_all(<<~SQL)
              SELECT event_id, event_type AS type, created_at AS timestamp
              FROM event_store_events
              WHERE created_at >= '#{since.utc.iso8601(6)}'
              ORDER BY created_at ASC
            SQL
            .map { |r| { event_id: r["event_id"], type: r["type"], timestamp: Time.parse(r["timestamp"].to_s) } }
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
