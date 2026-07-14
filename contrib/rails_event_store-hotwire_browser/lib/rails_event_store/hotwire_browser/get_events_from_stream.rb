# frozen_string_literal: true

module RailsEventStore
  module HotwireBrowser
    GetEventsFromStream =
      Struct.new(:event_store, :stream_name, :page, keyword_init: true) do
        def initialize(event_store:, stream_name:, page:)
          super(event_store: event_store, stream_name: stream_name, page: page || {})
        end

        def events
          case direction
          when :forward
            read(event_store.read, position).reverse
          when :backward
            read(event_store.read.backward, position)
          end
        end

        def pagination
          found = events
          {}.tap do |h|
            if prev_event?(found)
              h[:prev] = { position: found.first.event_id, direction: :forward }
              h[:first] = { position: :head, direction: :backward }
            end

            if next_event?(found)
              h[:next] = { position: found.last.event_id, direction: :backward }
              h[:last] = { position: :head, direction: :forward }
            end
          end
        end

        def count
          Integer(page["count"] || PAGE_SIZE)
        end

        private

        def read(reader, position)
          spec = reader.limit(count)
          spec = spec.stream(stream_name) unless stream_name.eql?(SERIALIZED_GLOBAL_STREAM_NAME)
          spec = spec.from(position) if position
          spec.to_a
        end

        def next_event?(found)
          return if found.empty?
          read(event_store.read.backward, found.last.event_id).any?
        end

        def prev_event?(found)
          return if found.empty?
          read(event_store.read, found.first.event_id).any?
        end

        def direction
          case page["direction"]
          when "forward"
            :forward
          else
            :backward
          end
        end

        def position
          page["position"] unless page["position"].nil? || page["position"] == "head"
        end
      end
  end
end
