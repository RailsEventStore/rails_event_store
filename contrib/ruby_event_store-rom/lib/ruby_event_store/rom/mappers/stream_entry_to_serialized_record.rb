# frozen_string_literal: true

require 'rom/transformer'

module RubyEventStore
  module ROM
    module Mappers
      class StreamEntryToSerializedRecord < ::ROM::Transformer
        relation :stream_entries
        register_as :stream_entry_to_serialized_record

        map_array do
          unwrap :event, %i[event_id data metadata event_type created_at valid_at]
          map_value :created_at, ->(time) { time.iso8601(TIMESTAMP_PRECISION) }
          map_value :valid_at,   ->(time) { time.iso8601(TIMESTAMP_PRECISION) }
          rename_keys created_at: :timestamp
          accept_keys %i[event_id data metadata event_type timestamp valid_at]
          constructor_inject RubyEventStore::SerializedRecord
        end
      end
    end
  end
end
