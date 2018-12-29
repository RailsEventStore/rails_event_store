module RubyEventStore
  module ROM
    module SQL
      module Relations
        class Events < ::ROM::Relation[:sql]
          schema(:event_store_events, as: :events, infer: true) do
            attribute :data, RubyEventStore::ROM::Types::SerializedRecordSerializer,
              read: RubyEventStore::ROM::Types::SerializedRecordDeserializer
            attribute :metadata, RubyEventStore::ROM::Types::SerializedRecordSerializer,
              read: RubyEventStore::ROM::Types::SerializedRecordDeserializer
            attribute :created_at, RubyEventStore::ROM::Types::DateTime
          end
        end
      end
    end
  end
end
