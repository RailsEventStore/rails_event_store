# frozen_string_literal: true

module RubyEventStore
  module Browser
    GetEventsFromStreams =
      Struct.new(:event_store, :stream_names, :cursor, :sort, :count, keyword_init: true) do
        def initialize(event_store:, stream_names:, cursor: nil, sort: nil, count: PAGE_SIZE)
          super(event_store: event_store, stream_names: stream_names, cursor: cursor, sort: sort, count: count)
        end

        def events
          @events ||= build_page
        end

        def more?
          events
          @more
        end

        def missing_stream_names
          stream_names.select { |name| name != SERIALIZED_GLOBAL_STREAM_NAME && chunks[name].empty? }
        end

        def next_cursor
          events.last && time_of(events.last.last).iso8601(TIMESTAMP_PRECISION)
        end

        private

        def build_page
          rows = stream_names.flat_map { |name| chunks[name].map { |event| [name, event] } }
          @more = full_chunks.any?
          return group(rows) unless @more

          boundary = full_chunks.map { |name| time_of(chunks[name].last) }.max
          page_rows = rows.select { |_, event| time_of(event) >= boundary }
          group(page_rows + drained_rows(boundary))
        end

        def chunks
          @chunks ||= stream_names.to_h { |name| [name, read_chunk(name)] }
        end

        def read_chunk(name)
          scope = time_sorted(stream_scope(name)).backward.limit(count)
          scope = scope.older_than(cursor_time) if cursor_time
          scope.to_a
        end

        def full_chunks
          stream_names.select { |name| chunks[name].size == count }
        end

        def drained_rows(boundary)
          full_chunks
            .select { |name| time_of(chunks[name].last) == boundary }
            .flat_map { |name| drain(name, boundary).map { |event| [name, event] } }
        end

        def drain(name, boundary)
          time_sorted(stream_scope(name)).between(boundary..boundary).to_a
        end

        def stream_scope(name)
          name == SERIALIZED_GLOBAL_STREAM_NAME ? event_store.read : event_store.read.stream(name)
        end

        def group(rows)
          rows
            .group_by { |_, event| event.event_id }
            .map { |_, list| [list.map(&:first).uniq, list.first.last] }
            .sort_by { |_, event| [time_of(event), event.event_id] }
            .reverse
        end

        def time_sorted(scope)
          as_of? ? scope.as_of : scope.as_at
        end

        def time_of(event)
          event.metadata.fetch(as_of? ? :valid_at : :timestamp)
        end

        def as_of?
          sort == "as_of"
        end

        def cursor_time
          @cursor_time ||= cursor && Time.iso8601(cursor)
        end
      end
  end
end
