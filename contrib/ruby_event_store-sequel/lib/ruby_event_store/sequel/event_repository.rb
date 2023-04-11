# frozen_string_literal: true

module RubyEventStore
  module Sequel
    class EventRepository
      def initialize(serializer:)
        @serializer = serializer
      end

      def append_to_stream(records, stream, expected_version)
      end

      def link_to_stream(event_ids, stream, expected_version)
      end

      def position_in_stream(event_id, stream)
      end

      def global_position(event_id)
      end

      def event_in_stream?(event_id, stream)
      end

      def delete_stream(stream)
      end

      def has_event?(event_id)
      end

      def last_stream_event(stream)
      end

      def read(specification)
      end

      def count(specification)
      end

      def update_messages(records)
      end

      def streams_of(event_id)
      end
    end
  end
end
