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

        POSITION_SHIFT = 1.freeze
        GLOBAL_STREAM = ::RubyEventStore::GLOBAL_STREAM

        # relations :event_streams
        # commands :create
        # struct_namespace Entities

        ### Writer interface

        def create(serialized_records, stream_name: nil, expected_version: ExpectedVersion.any)
          events.transaction(savepoint: true) do
            events.changeset(CreateEventsChangeset, serialized_records).commit.tap do
              if stream_name
                link(
                  serialized_records.map(&:event_id),
                  stream_name,
                  expected_version,
                  global_stream: true
                )
              end
            end
          end
        end

        def link(event_ids, stream_name, expected_version, global_stream: false)
          event_ids = [event_ids].flatten

          (event_ids - events.where(id: event_ids).pluck(:id)).each do |id|
            raise RubyEventStore::EventNotFound.new(id)
          end

          resolved_version = expected_version.resolve_for(stream_name) do
            event_streams.where(stream: stream_name).max(:position)
          end
          
          tuples = []

          event_ids.each_with_index do |event_id, index|
            tuples << {
              stream:   stream_name,
              position: compute_position(resolved_version, index),
              event_id: event_id
            } unless stream_name.eql?(GLOBAL_STREAM)
  
            tuples << {
              stream: GLOBAL_STREAM,
              event_id: event_id
            } if global_stream
          end
  
          event_streams.changeset(:create, tuples).commit
        end
    
        ### Reader interface
  
        def exist?(event_id)
          events.where(id: event_id).exist?
        end
  
        def fetch(event_id)
          events.where(id: event_id).map_with(:serialized_record_mapper).one!
        end
  
        def read(direction, stream_name, from: :head, limit: nil)
          order, operator = direction == :backward ? [:desc, :<] : [:asc, :>]

          stream = events_for(stream_name, order)
          stream = stream.limit(limit) if limit
          
          unless from.equal?(:head)
            conditions = event_streams[:id].__send__(operator, fetch_id_for(stream_name, from))
            stream = stream.where(conditions)
          end

          stream.to_a
        end
  
      private

        def events_for(stream_name, direction)
          order_columns = %i[position id]
          order_columns.delete(:position) if stream_name == GLOBAL_STREAM

          events
            .join(event_streams, event_id: :id)
            .where(event_streams[:stream].in(stream_name))
            .order { |r| order_columns.map { |c| r[:event_streams][c].__send__(direction) } }
            .map_with(:serialized_record_mapper)
        end

        def fetch_id_for(stream_name, event_id)
          event_streams.where(stream: stream_name, event_id: event_id).limit(1).pluck(:id).first
        end

        def compute_position(version, offset)
          version + offset + POSITION_SHIFT if version
        end
      end
    end
  end
end
