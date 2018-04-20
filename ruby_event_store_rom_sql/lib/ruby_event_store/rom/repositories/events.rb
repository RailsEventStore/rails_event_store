require_relative '../mappers/event_to_serialized_record'

module RubyEventStore
  module ROM
    module Repositories
      class Events < ::ROM::Repository[:events]
        class CreateEventsChangeset < ::ROM::Changeset::Create
          # Convert to Hash
          map(&:to_h)

          map do
            rename_keys event_id: :id
            accept_keys %i[id data metadata event_type]
          end
        end

        def create(serialized_records)
          create_changeset(serialized_records).commit
        end

        def create_changeset(serialized_records)
          events.changeset(CreateEventsChangeset, serialized_records)
        end

        def find_nonexistent_pks(event_ids)
          event_ids - events.by_pks(event_ids).pluck(:id)
        end

        def exist?(event_id)
          events.by_pk(event_id).exist?
        end
  
        def by_id(event_id)
          events.map_with(:event_to_serialized_record).by_pk(event_id).one!
        end

        def read(direction, stream, from: :head, limit: nil)
          unless from.equal?(:head)
            offset_entry_id = stream_entries.by_stream_and_event_id(stream, from)[:id]
          end
          
          stream_entries
            .ordered(direction, stream, offset_entry_id)
            .limit(limit)
            .combine(:event)
            .map_with(:stream_entry_to_serialized_record)
            .each
        end
      end
    end
  end
end
