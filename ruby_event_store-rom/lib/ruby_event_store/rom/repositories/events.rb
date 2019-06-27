# frozen_string_literal: true

require_relative '../mappers/event_to_serialized_record'
require_relative '../changesets/create_events'
require_relative '../changesets/update_events'

module RubyEventStore
  module ROM
    module Repositories
      class Events < ::ROM::Repository[:events]
        def create_changeset(serialized_records)
          events.create_changeset(serialized_records)
        end

        def update_changeset(serialized_records)
          events.update_changeset(serialized_records)
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
          query = read_scope(specification)

          if specification.batched?
            BatchEnumerator.new(
              specification.batch_size,
              specification.limit,
              ->(offset, limit) { query_builder(query, offset: offset, limit: limit).to_ary }
            ).each
          else
            query = query_builder(query, limit: (specification.limit if specification.limit?))
            if !specification.start && !specification.stop
              specification.first? || specification.last? ? query.first : query.each
            elsif specification.last?
              query.to_ary.last
            else
              specification.first? ? query.first : query.each
            end
          end
        end

        def count(specification)
          query = read_scope(specification)
          query = query.take(specification.limit) if specification.limit?
          query.count
        end

        protected

        def read_scope(specification)
          offset_entry_id = stream_entries.by_stream_and_event_id(specification.stream, specification.start).fetch(:id) if specification.start
          stop_entry_id = stream_entries.by_stream_and_event_id(specification.stream, specification.stop).fetch(:id) if specification.stop

          direction = specification.forward? ? :forward : :backward

          if specification.last? && !specification.start && !specification.stop
            direction = specification.forward? ? :backward : :forward
          end

          query = stream_entries.ordered(direction, specification.stream, offset_entry_id, stop_entry_id)
          query = query.by_event_id(specification.with_ids) if specification.with_ids
          query = query.by_event_type(specification.with_types) if specification.with_types?
          query
        end

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
