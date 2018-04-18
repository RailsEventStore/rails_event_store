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

        # relations :stream_entries
        # commands :create
        # struct_namespace Entities
        # auto_struct false

        ### Writer interface

        def create(serialized_records)
          events.changeset(CreateEventsChangeset, serialized_records).commit
        end

        ### Reader interface

        def exist?(event_id)
          events.by_pk(event_id).exist?
        end
  
        def by_id(event_id)
          events.map_with(:serialized_record_mapper).by_pk(event_id).one!
        end

        def read(direction, stream, from: :head, limit: nil)
          unless from.equal?(:head)
            offset_entry_id = stream_entries.by_stream_and_event_id(stream, from)[:id]
          end
          
          Mappers::SerializedRecord.new.call(
            stream_entries
              .ordered(direction, stream, offset_entry_id)
              .limit(limit)
              .combine(:event)
              .to_a
              .map(&:event)
          )

        rescue ::ROM::TupleCountMismatchError
          raise EventNotFound.new(from)
        end
      end
    end
  end
end
