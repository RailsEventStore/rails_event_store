# frozen_string_literal: true

module RubyEventStore
  module Browser
    class GetEventsFromStream
      HEAD = Object.new

      def initialize(event_store:, routing:, stream_name:, page:)
        @event_store = event_store
        @routing = routing
        @stream_name = stream_name
        @page = page || {}
      end

      def to_h
        { data: events.map { |e| JsonApiEvent.new(e, nil).to_h }, links: links }
      end

      private

      attr_reader :event_store, :routing, :stream_name, :page

      def events
        @events ||=
          case direction
          when :forward
            events_forward(position).reverse
          when :backward
            events_backward(position)
          end
      end

      def links
        @links ||=
          {}.tap do |h|
            if prev_event?
              h[:prev] = prev_page_link(events.first.event_id)
              h[:first] = first_page_link
            end

            if next_event?
              h[:next] = next_page_link(events.last.event_id)
              h[:last] = last_page_link
            end
          end
      end

      def events_forward(position)
        spec = event_store.read.limit(count)
        spec = spec.stream(stream_name) unless stream_name.eql?(
          SERIALIZED_GLOBAL_STREAM_NAME
        )
        spec = spec.from(position) unless position.equal?(HEAD)
        spec.to_a
      end

      def events_backward(position)
        spec = event_store.read.limit(count).backward
        spec = spec.stream(stream_name) unless stream_name.eql?(
          SERIALIZED_GLOBAL_STREAM_NAME
        )
        spec = spec.from(position) unless position.equal?(HEAD)
        spec.to_a
      end

      def next_event?
        return if events.empty?
        events_backward(events.last.event_id).any?
      end

      def prev_event?
        return if events.empty?
        events_forward(events.first.event_id).any?
      end

      def prev_page_link(event_id)
        routing.paginated_events_from_stream_url(
          id: stream_name,
          position: event_id,
          direction: :forward,
          count: count
        )
      end

      def next_page_link(event_id)
        routing.paginated_events_from_stream_url(
          id: stream_name,
          position: event_id,
          direction: :backward,
          count: count
        )
      end

      def first_page_link
        routing.paginated_events_from_stream_url(
          id: stream_name,
          position: :head,
          direction: :backward,
          count: count
        )
      end

      def last_page_link
        routing.paginated_events_from_stream_url(
          id: stream_name,
          position: :head,
          direction: :forward,
          count: count
        )
      end

      def count
        Integer(page["count"] || PAGE_SIZE)
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
