# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Memory
      module Relations
        class Events < ::ROM::Relation[:memory]
          schema(:events) do
            attribute :id, ::ROM::Types::Strict::String.meta(primary_key: true)
            attribute :event_type, ::ROM::Types::Strict::String
            attribute :metadata, ::ROM::Types::Strict::String.optional
            attribute :data, ::ROM::Types::Strict::String
            attribute :created_at, RubyEventStore::ROM::Types::DateTime
          end

          def create_changeset(tuples)
            events.changeset(Changesets::CreateEvents, tuples)
          end

          def update_changeset(tuples)
            events.changeset(Changesets::UpdateEvents, tuples)
          end

          def insert(tuple)
            verify_uniquness!(tuple)
            super
          end

          def for_stream_entries(_assoc, stream_entries)
            restrict(id: stream_entries.map { |e| e[:event_id] })
          end

          def by_pk(id)
            restrict(id: id)
          end

          def exist?
            one?
          end

          def pluck(name)
            map { |e| e[name] }
          end

          private

          def verify_uniquness!(tuple)
            return unless by_pk(tuple[:id]).exist?

            raise TupleUniquenessError.for_event_id(tuple[:id])
          end
        end
      end
    end
  end
end
