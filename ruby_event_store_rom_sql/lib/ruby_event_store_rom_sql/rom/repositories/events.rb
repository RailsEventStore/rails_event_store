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
  
        def has_event?(event_id)
          events.where(id: event_id).exist?
        end
  
        def fetch(event_id)
          events.where(id: event_id).map_with(:serialized_record_mapper).one!
        rescue ::ROM::TupleCountMismatchError
          raise RubyEventStore::EventNotFound.new(event_id)
        end
  
        def read_events_forward(stream_name, after: :head, limit: nil)
          stream = forward_for(stream_name)
  
          unless after.equal?(:head)
            stream = stream.where(event_streams[:id] > fetch_stream_id_for(stream_name, after))
          end

          stream = stream.limit(limit) if limit
          stream.map_with(:serialized_record_mapper).to_a
        end
  
        def read_events_backward(stream_name, before: :head, limit: nil)
          stream = backward_for(stream_name)
          
          unless before.equal?(:head)
            stream = stream.where(event_streams[:id] < fetch_stream_id_for(stream_name, before))
          end

          stream = stream.limit(limit) if limit
          stream.map_with(:serialized_record_mapper).to_a
        end
  
        def last_stream_event(stream_name)
          backward_for(stream_name).map_with(:serialized_record_mapper).first
        end
  
        def detect_invalid_event_ids(event_ids)
          event_ids - events.where(id: event_ids).pluck(:id)
        end
  
      private

        def fetch_stream_id_for(stream_name, event_id)
          event_streams.where(stream: stream_name, event_id: event_id).limit(1).pluck(:id).first
        end
  
        def forward_for(stream_name)
          events_for(stream_name, :asc)
        end
  
        def backward_for(stream_name)
          events_for(stream_name, :desc)
        end

        def events_for(stream_name, direction)
          order_columns = %i[position id]
          order_columns.delete(:position) if stream_name == RubyEventStore::GLOBAL_STREAM

          events
            .join(event_streams, event_id: :id)
            .where(event_streams[:stream].in(stream_name))
            .order { |r| order_columns.map { |c| r[:event_streams][c].__send__(direction) } }
        end
      end
    end
  end
end
