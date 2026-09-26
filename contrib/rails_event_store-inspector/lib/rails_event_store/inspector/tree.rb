# frozen_string_literal: true

require "set"

module RailsEventStore
  module Inspector
    class Tree
      MAX_REQUESTS = 10

      Group = Struct.new(:label, :roots, :swimlane_url, :stream_count)
      Event = Struct.new(:type, :duration, :url, :chain_url, :handler_count, :handlers, :infra, :orphans)
      Handler = Struct.new(:name, :duration, :enqueued, :children)

      def initialize(entries, links)
        @entries = entries.sort_by { |e| e[:started_at] }
        @links = links
      end

      def groups
        @groups ||= grouped.map { |request_id, entries| build_group(request_id, entries) }
      end

      def event_count
        @entries.count { |e| e[:kind] == :event }
      end

      private

      def grouped
        @entries.reject { |e| e[:kind] == :stream }.group_by { |e| e[:request_id] }.to_a.last(MAX_REQUESTS)
      end

      def streams_by_event
        @streams_by_event ||= @entries.select { |e| e[:kind] == :stream }.group_by { |e| e[:event_id] }
      end

      def build_group(request_id, entries)
        @enqueued = entries.select { |e| e[:kind] == :enqueued }.map { |e| e[:job] }.to_set
        @events = entries.select { |e| e[:kind] == :event }
        @handlers = entries.select { |e| e[:kind] == :handler }.group_by { |e| e[:event_id] }
        @children = @events.group_by { |e| e[:causation_id] }
        known = @events.map { |e| e[:event_id] }.to_set

        roots = @events.reject { |e| known.include?(e[:causation_id]) }
        streams = domain_streams(entries)

        Group.new(request_label(request_id), roots.map { |e| build_event(e) }, @links.swimlane(streams), streams.size)
      end

      def domain_streams(entries)
        entries
          .select { |e| e[:kind] == :event }
          .flat_map { |e| streams_by_event.fetch(e[:event_id], []) }
          .map { |e| e[:stream] }
          .reject { |name| name.nil? || name.start_with?("$") || name == "all" }
          .uniq
      end

      def build_event(entry)
        all = @handlers.fetch(entry[:event_id], [])
        own, infra = all.partition { |h| !h[:infra] }
        kids = @children.fetch(entry[:event_id], [])
        labels = all.map { |h| h[:subscriber] }.to_set

        Event.new(
          entry[:event_type],
          ms(entry[:duration]),
          @links.event(entry[:event_id]),
          @links.by_correlation(entry[:correlation_id]),
          own.size,
          own.map { |h| build_handler(h, kids.select { |k| k[:producer] == h[:subscriber] }) },
          infra.map { |h| h[:subscriber].to_s.split("::").last },
          kids.reject { |k| labels.include?(k[:producer]) }.map { |k| build_event(k) },
        )
      end

      def build_handler(entry, children)
        Handler.new(
          entry[:subscriber],
          ms(entry[:duration]),
          entry[:async] ? @enqueued.include?(entry[:subscriber]) : nil,
          children.map { |c| build_event(c) },
        )
      end

      def request_label(request_id)
        return "outside request" if request_id.nil?
        "req #{request_id.to_s[0, 8]}…"
      end

      def ms(seconds)
        format("%.1f ms", seconds.to_f * 1000)
      end
    end
  end
end
