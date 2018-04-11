module RubyEventStore
  module ROM
    module Relations
      class Events < ::ROM::Relation[:sql]
        schema(:event_store_events, as: :events, infer: true) do
          attribute :id, ::ROM::Types::String.meta(primary_key: true)
          attribute :event_type, ::ROM::Types::String
          attribute :metadata, ::ROM::Types::String.optional
          attribute :data, ::ROM::Types::String
          attribute :created_at, ::ROM::Types::DateTime.default { Time.now.utc }

          associations do
            has_many :stream_entries, foreign_key: :event_id
          end
        end
  
        # struct_namespace Entities
        # auto_struct true
      end
    end
  end
end
