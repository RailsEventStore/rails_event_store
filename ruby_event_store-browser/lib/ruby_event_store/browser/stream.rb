module RubyEventStore
  module Browser
    class Stream
      attr_reader :event_store, :params, :url_builder
      
      def initialize(event_store:, params:, url_builder:)
        @event_store = event_store
        @params      = params
        @url_builder = url_builder
      end

      def as_json
        {
          data:  events.map { |e| JsonApiEvent.new(e).to_h },
          links: links
        }
      end

      def events
        @events ||= case direction
                    when :forward
                      events_forward(position).reverse
                    when :backward
                      events_backward(position)
                    end
      end

      def links
        @links ||= {}.tap do |h|
          if prev_event?(events)
            h[:prev] = prev_page_link(events.first.event_id)
            h[:first] = first_page_link
          end

          if next_event?(events)
            h[:next] = next_page_link(events.last.event_id)
            h[:last] = last_page_link
          end
        end
      end
      
      def events_forward(start)
        if stream_name.eql?(SERIALIZED_GLOBAL_STREAM_NAME)
          event_store.read.limit(count).from(start).each.to_a
        else
          event_store.read.limit(count).from(start).stream(stream_name).each.to_a
        end
      end

      def events_backward(start)
        if stream_name.eql?(SERIALIZED_GLOBAL_STREAM_NAME)
          event_store.read.limit(count).from(start).backward.each.to_a
        else
          event_store.read.limit(count).from(start).stream(stream_name).backward.each.to_a
        end
      end

      def next_event?(events)
        return if events.empty?
        events_backward(events.last.event_id).any?
      end

      def prev_event?(events)
        return if events.empty?
        events_forward(events.first.event_id).any?
      end

      def prev_page_link(event_id)
        url_builder.call(id: stream_name, position: event_id, direction: :forward, count: count)
      end

      def next_page_link(event_id)
        url_builder.call(id: stream_name, position: event_id, direction: :backward, count: count)
      end

      def first_page_link
        url_builder.call(id: stream_name, position: :head, direction: :backward, count: count)
      end

      def last_page_link
        url_builder.call(id: stream_name, position: :head, direction: :forward, count: count)
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
    end
  end
end