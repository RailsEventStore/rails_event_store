# frozen_string_literal: true

module RubyEventStore
  module ROM
    module SQL
      module Relations
        class Events < ::ROM::Relation[:sql]
          schema(:event_store_events, as: :events, infer: true) do
            attribute :data, RubyEventStore::ROM::Types::RecordSerializer,
                      read: RubyEventStore::ROM::Types::RecordDeserializer
            attribute :metadata, RubyEventStore::ROM::Types::RecordSerializer,
                      read: RubyEventStore::ROM::Types::RecordDeserializer
            attribute :created_at, RubyEventStore::ROM::Types::DateTime
            attribute :valid_at, RubyEventStore::ROM::Types::DateTime
          end

          def create_changeset(tuples)
            events.changeset(Changesets::CreateEvents, tuples)
          end

          def update_changeset(tuples)
            events.changeset(Changesets::UpdateEvents, tuples)
          end
        end
      end
    end
  end
end
