# frozen_string_literal: true

require 'rom/transformer'

module RubyEventStore
  module ROM
    module Mappers
      class StreamEntryToSerializedRecord < ::ROM::Transformer
        relation :stream_entries
        register_as :stream_entry_to_serialized_record

        map_array do
          unwrap :event, %i[data metadata event_type]
          accept_keys %i[event_id data metadata event_type]
          constructor_inject RubyEventStore::SerializedRecord
        end
      end
    end
  end
end
