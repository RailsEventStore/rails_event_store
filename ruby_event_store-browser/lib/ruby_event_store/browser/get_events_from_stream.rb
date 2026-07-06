# frozen_string_literal: true

module RubyEventStore
  module Browser
    class GetEventsFromStream
      HEAD = Object.new

      def initialize(event_store:, stream_name:, page:)
        @event_store = event_store
        @stream_name = stream_name
        @page = page || {}
      end

      def events
        @events ||=
          case direction
          when :forward
            read(event_store.read, position).reverse
          when :backward
            read(event_store.read.backward, position)
          end
      end

      def pagination
        @pagination ||=
          {}.tap do |h|
            if prev_event?
              h[:prev] = { position: events.first.event_id, direction: :forward }
              h[:first] = { position: :head, direction: :backward }
            end

            if next_event?
              h[:next] = { position: events.last.event_id, direction: :backward }
              h[:last] = { position: :head, direction: :forward }
            end
          end
      end

      def count
        Integer(page["count"] || PAGE_SIZE)
      end

      private

      attr_reader :event_store, :stream_name, :page

      def read(reader, position)
        spec = reader.limit(count)
        spec = spec.stream(stream_name) unless stream_name.eql?(SERIALIZED_GLOBAL_STREAM_NAME)
        spec = spec.from(position) unless position.equal?(HEAD)
        spec.to_a
      end

      def next_event?
        return if events.empty?
        read(event_store.read.backward, events.last.event_id).any?
      end

      def prev_event?
        return if events.empty?
        read(event_store.read, events.first.event_id).any?
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
        case page["position"]
        when "head", nil
          HEAD
        else
          page.fetch("position")
        end
      end
    end
  end
end
