require_relative '../mappers/event_to_serialized_record'

module RubyEventStore
  module ROM
    module Repositories
      class Events < ::ROM::Repository[:events]
        class Create < ::ROM::Changeset::Create
          # Convert to Hash
          map(&:to_h)

          map do
            rename_keys event_id: :id
            accept_keys %i[id data metadata event_type]
          end

          map do |tuple|
            Hash(created_at: Time.now).merge(tuple)
          end
        end

        def create_changeset(serialized_records)
          events.changeset(Create, serialized_records)
        end

        def find_nonexistent_pks(event_ids)
          return event_ids unless event_ids.any?
          event_ids - events.by_pk(event_ids).pluck(:id)
        end

        def exist?(event_id)
          events.by_pk(event_id).exist?
        end

        def by_id(event_id)
          events.map_with(:event_to_serialized_record).by_pk(event_id).one!
        end

        MATERIALIZE_READ_AS = {
          RubyEventStore::Specification::BATCH => :to_ary,
          RubyEventStore::Specification::FIRST => :first,
          RubyEventStore::Specification::LAST  => :first
        }.freeze

        def read(direction, stream, from:, limit:, read_as:, batch_size:)
          unless from.equal?(:head)
            offset_entry_id = stream_entries.by_stream_and_event_id(stream, from).fetch(:id)
          end

          # Note: `last` is problematic, so we switch direction and get `first`.
          #       See `MATERIALIZE_READ_AS`
          if read_as == RubyEventStore::Specification::LAST
            direction = direction == :forward ? :backward : :forward
          end

          query = stream_entries.ordered(direction, stream, offset_entry_id)

          if read_as == RubyEventStore::Specification::BATCH
            reader = ->(offset, limit) do
              query_builder(query, offset: offset, limit: limit).to_ary
            end
            BatchEnumerator.new(batch_size, limit || Float::INFINITY, reader).each
          else
            materialize_method = MATERIALIZE_READ_AS.fetch(read_as, :each)
            query_builder(query, limit: limit).__send__(materialize_method)
          end
        end

      protected

        def query_builder(query, offset: nil, limit: nil)
          query = query.offset(offset) if offset
          query = query.take(limit)    if limit

          query
            .combine(:event)
            .map_with(:stream_entry_to_serialized_record, auto_struct: false)
        end
      end
    end
  end
end
