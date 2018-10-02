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

        def last_stream_event(stream)
          query = stream_entries.ordered(:backward, stream)
          query = query_builder(query, limit: 1)
          query.first
        end

        def read(specification)
          unless specification.head?
            offset_entry_id = stream_entries.by_stream_and_event_id(specification.stream, specification.start).fetch(:id)
          end

          direction = specification.forward? ? :forward : :backward

          limit = specification.limit if specification.limit?

          if specification.last? && specification.head?
            direction = specification.forward? ? :backward : :forward
          end

          query = stream_entries.ordered(direction, specification.stream, offset_entry_id)

          query = query.by_event_id(specification.with_ids) if specification.with_ids

          if specification.batched?
            reader = ->(offset, limit) do
              query_builder(query, offset: offset, limit: limit).to_ary
            end
            BatchEnumerator.new(specification.batch_size, limit || Float::INFINITY, reader).each
          else
            query = query_builder(query, limit: limit)
            if specification.head?
              specification.first? || specification.last? ? query.first : query.each
            else
              if specification.last?
                query.to_ary.last
              else
                specification.first? ? query.first : query.each
              end
            end
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
