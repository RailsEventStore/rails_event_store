require 'rom/transformer'

module RubyEventStoreRomSql
  module ROM
    module Mappers
      class SerializedRecord < ::ROM::Transformer
        relation :events
        register_as :serialized_record_mapper
      
        map_array do
          rename_keys id: :event_id
          accept_keys %i[event_id data metadata event_type]
          constructor_inject RubyEventStore::SerializedRecord
        end
      end
    end
  end
end
