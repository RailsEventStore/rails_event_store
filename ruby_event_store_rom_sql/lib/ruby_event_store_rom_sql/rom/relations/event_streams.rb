require 'securerandom'

module RubyEventStoreRomSql
  module ROM
    module Relations
      class EventStreams < ::ROM::Relation[:sql]
        schema(:event_store_events_in_streams, as: :event_streams, infer: true) do
          attribute :id, ::ROM::Types::Int
          attribute :stream, ::ROM::Types::String
          attribute :position, ::ROM::Types::Int.optional
          attribute :event_id, ::ROM::Types::String.meta(foreign_key: true, relation: :events)
          attribute :created_at, ::ROM::Types::DateTime.default { Time.now.utc }

          primary_key :id
    
          associations do
            belongs_to :events, as: :event
          end
        end
  
        struct_namespace Entities
        auto_struct true
      end
    end
  end
end
