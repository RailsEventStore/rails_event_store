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

        def read(direction, stream, from:, limit:, read_as:, batch_size:)
          unless from.equal?(:head)
            offset_entry_id = stream_entries.by_stream_and_event_id(stream, from).fetch(:id)
          end

          if read_as == RubyEventStore::Specification::BATCH
            reader = ->(offset, limit) do
              stream_entries
                .ordered(direction, stream, offset_entry_id)
                .offset(offset)
                .take(limit)
                .combine(:event)
                .map_with(:stream_entry_to_serialized_record, auto_struct: false)
                .to_ary
            end
            BatchEnumerator.new(batch_size, limit || Float::INFINITY, reader).each
          elsif read_as == RubyEventStore::Specification::FIRST
            stream_entries
              .ordered(direction, stream, offset_entry_id)
              .combine(:event)
              .map_with(:stream_entry_to_serialized_record, auto_struct: false)
              .to_ary.first
          elsif read_as == RubyEventStore::Specification::LAST
            stream_entries
              .ordered(direction, stream, offset_entry_id)
              .combine(:event)
              .map_with(:stream_entry_to_serialized_record, auto_struct: false)
              .to_ary.last
          else
            stream_entries
              .ordered(direction, stream, offset_entry_id)
              .take(limit)
              .combine(:event)
              .map_with(:stream_entry_to_serialized_record, auto_struct: false)
              .each
          end
        end
      end
    end
  end
end
