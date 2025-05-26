# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module BatchMapping
      def records_to_events(records)
        records.map { |record| record_to_event(record) }
      end
    end
  end
end
