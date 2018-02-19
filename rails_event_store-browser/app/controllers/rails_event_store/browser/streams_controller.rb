module RailsEventStore
  module Browser
    class StreamsController < ApplicationController
      def index
        links   = {}
        streams = case direction
        when :forward
          items = event_store.get_all_streams
          items = items.drop_while { |s| !s.name.eql?(position) }.drop(1) unless position.equal?(:head)
          items.take(count).reverse
        when :backward
          items = event_store.get_all_streams.reverse
          items = items.drop_while { |s| !s.name.eql?(position) }.drop(1) unless position.equal?(:head)
          items.take(count)
        end

        if next_stream?(streams)
          links[:next] = streams_next_page_link(streams.last.name)
          links[:last] = streams_last_page_link
        end

        if prev_stream?(streams)
          links[:prev]  = streams_prev_page_link(streams.first.name)
          links[:first] = streams_first_page_link
        end

        render json: {
          data: streams.map { |s| serialize_stream(s) },
          links: links
        }, content_type: 'application/vnd.api+json'
      end

      def show
        links  = {}
        events = case direction
        when :forward
          event_store
            .read_events_forward(stream_name, start: position, count: count)
            .reverse
        when :backward
          event_store
            .read_events_backward(stream_name, start: position, count: count)
        end

        if prev_event?(events)
          links[:prev]  = prev_page_link(events.first.event_id)
          links[:first] = first_page_link
        end

        if next_event?(events)
          links[:next] = next_page_link(events.last.event_id)
          links[:last] = last_page_link
        end

        render json: {
          data: events.map { |e| serialize_event(e) },
          links: links
        }, content_type: 'application/vnd.api+json'
      end

      private

      def next_stream?(streams)
        return if streams.empty?
        event_store.get_all_streams
          .reverse
          .drop_while { |s| !s.name.eql?(streams.last.name) }
          .drop(1)
          .present?
      end

      def prev_stream?(streams)
        return if streams.empty?
        event_store.get_all_streams
          .drop_while { |s| !s.name.eql?(streams.first.name) }
          .drop(1)
          .present?
      end

      def streams_next_page_link(stream_name)
        streams_url(position: stream_name, direction: :backward, count: count)
      end

      def streams_prev_page_link(stream_name)
        streams_url(position: stream_name, direction: :forward, count: count)
      end

      def streams_first_page_link
        streams_url(position: :head, direction: :backward, count: count)
      end

      def streams_last_page_link
        streams_url(position: :head, direction: :forward, count: count)
      end

      def next_event?(events)
        return if events.empty?
        event_store.read_events_backward(stream_name, start: events.last.event_id).present?
      end

      def prev_event?(events)
        return if events.empty?
        event_store.read_events_forward(stream_name, start: events.first.event_id).present?
      end

      def prev_page_link(event_id)
        stream_url(position: event_id, direction: :forward, count: count)
      end

      def next_page_link(event_id)
        stream_url(position: event_id,  direction: :backward, count: count)
      end

      def first_page_link
        stream_url(position: :head, direction: :backward, count: count)
      end

      def last_page_link
        stream_url(position: :head, direction: :forward, count: count)
      end

      def count
        Integer(params.fetch(:count, PAGE_SIZE))
      end

      def direction
        case params[:direction]
        when 'forward'
          :forward
        else
          :backward
        end
      end

      def position
        case params[:position]
        when nil, 'head'
          :head
        else
          params.fetch(:position)
        end
      end

      def stream_name
        params.fetch(:id)
      end

      def serialize_stream(stream)
        {
          id: stream.name,
          type: "streams"
        }
      end

      def serialize_event(event)
        {
          id: event.event_id,
          type: "events",
          attributes: {
            event_type: event.class.to_s,
            data: event.data,
            metadata: event.metadata
          }
        }
      end
    end
  end
end