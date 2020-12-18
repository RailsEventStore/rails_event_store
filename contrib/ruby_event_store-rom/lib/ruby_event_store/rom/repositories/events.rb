# frozen_string_literal: true

require_relative '../changesets/create_events'
require_relative '../changesets/update_events'
require_relative '../mappers/event_to_serialized_record'


module RubyEventStore
  module ROM
    module Repositories
      class Events < ::ROM::Repository[:events]
        def create_changeset(records)
          events.create_changeset(records)
        end

        def update_changeset(records)
          events.update_changeset(records)
        end

        def find_nonexistent_pks(event_ids)
          return event_ids unless event_ids.any?

          event_ids - events.by_event_id(event_ids).pluck(:event_id)
        end

        def exist?(event_id)
          events.by_event_id(event_id).exist?
        end

        def last_stream_event(stream, serializer)
          query = stream_entries.ordered(:backward, stream)
          query = query.combine(:event)
          query = query.map_with(:stream_entry_to_serialized_record, auto_struct: false)
          query = query_builder(serializer, query, limit: 1)
          query.first
        end

        def read(specification, serializer)
          query = read_scope(specification)

          if specification.batched?
            BatchEnumerator.new(
              specification.batch_size,
              specification.limit,
              ->(offset, limit) { query_builder(serializer, query, offset: offset, limit: limit).to_ary }
            ).each
          else
            query = query_builder(serializer, query, limit: (specification.limit if specification.limit?))
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
          direction = specification.forward? ? :forward : :backward

          if specification.last? && !specification.start && !specification.stop
            direction = specification.forward? ? :backward : :forward
          end

          if specification.stream.global?
            offset_entry_id = events.by_event_id(specification.start).one!.fetch(:id) if specification.start
            stop_entry_id   = events.by_event_id(specification.stop).one!.fetch(:id)  if specification.stop

            query = events.ordered(direction, offset_entry_id, stop_entry_id, specification.time_sort_by)
            query = query.map_with(:event_to_serialized_record, auto_struct: false)
          else
            offset_entry_id = stream_entries.by_stream_and_event_id(specification.stream, specification.start).fetch(:id) if specification.start
            stop_entry_id   = stream_entries.by_stream_and_event_id(specification.stream, specification.stop).fetch(:id)  if specification.stop

            query = stream_entries.ordered(direction, specification.stream, offset_entry_id, stop_entry_id, specification.time_sort_by)
            query = query.combine(:event)
            query = query.map_with(:stream_entry_to_serialized_record, auto_struct: false)
          end

          query = query.by_event_id(specification.with_ids)                    if specification.with_ids
          query = query.by_event_type(specification.with_types)                if specification.with_types?
          query = query.older_than(specification.older_than)                   if specification.older_than
          query = query.older_than_or_equal(specification.older_than_or_equal) if specification.older_than_or_equal
          query = query.newer_than(specification.newer_than)                   if specification.newer_than
          query = query.newer_than_or_equal(specification.newer_than_or_equal) if specification.newer_than_or_equal
          query
        end

        def query_builder(serializer, query, offset: nil, limit: nil)
          query = query.offset(offset) if offset
          query = query.take(limit)    if limit
          query
            .to_a
            .map { |serialized_record| serialized_record.deserialize(serializer) }
        end
      end
    end
  end
end
