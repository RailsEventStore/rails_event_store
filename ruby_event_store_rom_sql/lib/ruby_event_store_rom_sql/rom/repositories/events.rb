module RubyEventStoreRomSql
  module ROM
    module Repositories
      class Events < ::ROM::Repository[:events]
        class CreateEventsChangeset < ::ROM::Changeset::Create
          map do |tuple|
            # Convert RubyEventStore::SerializedRecord to Hash
            %i[event_id data metadata event_type].each_with_object({}) do |key, hash|
              hash[key] = tuple.__send__(key)
            end
          end

          map do
            rename_keys event_id: :id
            accept_keys %i[id data metadata event_type]
          end
        end

        # relations :event_streams
        # commands :create
        # struct_namespace Entities

        ### Writer interface

        def create(*serialized_records)
          # mapper = mappers[:serialized_record_to_hash]
          # events.changeset(:create, serialized_records).commit
          events.changeset(CreateEventsChangeset, serialized_records).commit
        end
  
        ### Reader interface
  
        def exist?(event_id)
          events.where(id: event_id).exist?
        end
  
        def fetch(event_id)
          events.where(id: event_id).map_with(:serialized_record_mapper).one!
        rescue ::ROM::TupleCountMismatchError
          raise RubyEventStore::EventNotFound.new(event_id)
        end
  
        def read(direction, stream_name, from: :head, limit: nil)
          order, operator = direction == :backward ? [:desc, :<] : [:asc, :>]

          stream = events_for(stream_name, order)
          
          unless from.equal?(:head)
            conditions = event_streams[:id].__send__(operator, fetch_id_for(stream_name, from))
            stream = stream.where(conditions)
          end

          stream = stream.limit(limit) if limit
          stream.map_with(:serialized_record_mapper).to_a
        end
  
        def last_position_for(stream_name)
          event_streams.where(stream: stream_name).max(:position)
        end
  
        def delete_stream(stream_name)
          event_streams.where(stream: stream_name).command(:delete).call
        end
  
        def detect_invalid_event_ids(event_ids)
          event_ids - events.where(id: event_ids).pluck(:id)
        end
  
      private

        def events_for(stream_name, direction)
          order_columns = %i[position id]
          order_columns.delete(:position) if stream_name == RubyEventStore::GLOBAL_STREAM

          events
            .join(event_streams, event_id: :id)
            .where(event_streams[:stream].in(stream_name))
            .order { |r| order_columns.map { |c| r[:event_streams][c].__send__(direction) } }
        end

        def fetch_id_for(stream_name, event_id)
          event_streams.where(stream: stream_name, event_id: event_id).limit(1).pluck(:id).first
        end
      end
    end
  end
end
