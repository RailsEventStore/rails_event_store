module RubyEventStore
  module ROM
    module Relations
      class Events < ::ROM::Relation[:sql]
        schema(:event_store_events, as: :events, infer: true) do
          attribute :id, ::ROM::Types::String.meta(primary_key: true)
          attribute :event_type, ::ROM::Types::String
          attribute :metadata, ::ROM::Types::String.optional
          attribute :data, ::ROM::Types::String

          associations do
            has_many :stream_entries
          end
        end
  
        def by_pks(ids)
          where(id: ids)
        end
      end
    end
  end
end
