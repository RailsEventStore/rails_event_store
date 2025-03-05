# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module BatchMapping
      def each_event_to_record(events)
        events.map { |event| event_to_record(event) }
      end

      def each_record_to_event(events)
        events.map { |event| record_to_event(event) }
      end
    end
  end
end
