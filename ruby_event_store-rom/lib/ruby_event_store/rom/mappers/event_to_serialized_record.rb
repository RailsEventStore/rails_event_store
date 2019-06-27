# frozen_string_literal: true

require 'rom/transformer'

module RubyEventStore
  module ROM
    module Mappers
      class EventToSerializedRecord < ::ROM::Transformer
        relation :events
        register_as :event_to_serialized_record

        map_array do
          rename_keys id: :event_id
          accept_keys %i[event_id data metadata event_type]
          constructor_inject RubyEventStore::SerializedRecord
        end
      end
    end
  end
end
