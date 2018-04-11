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

        # relations :stream_entries
        # commands :create
        # struct_namespace Entities

        ### Writer interface

        def create(serialized_records, stream: nil, expected_version: nil)
          events.transaction(savepoint: true) do
            events.changeset(CreateEventsChangeset, serialized_records).commit.tap do
              if stream
                link(
                  serialized_records.map(&:event_id),
                  stream,
                  expected_version || ExpectedVersion.any,
                  global_stream: true
                )
              end
            end
          end
        end

        def link(event_ids, stream, expected_version, global_stream: nil)
          (event_ids - events.where(id: event_ids).select(:id).pluck(:id)).each do |id|
            raise EventNotFound.new(id)
          end

          resolved_version = expected_version.resolve_for(stream, ->(stream) {
            stream_entries.where(stream: stream.name).max(:position)
          })

          tuples = []

          event_ids.each_with_index do |event_id, index|
            tuples << {
              stream:   stream.name,
              position: compute_position(resolved_version, index),
              event_id: event_id
            } unless stream.global?

            tuples << {
              stream: GLOBAL_STREAM,
              event_id: event_id
            } if global_stream
          end

          stream_entries.changeset(:create, tuples).commit
        end

        ### Reader interface

        def exist?(event_id)
          events.where(id: event_id).exist?
        rescue Sequel::DatabaseError => ex
          return false if ex.message =~ /PG::InvalidTextRepresentation.*uuid/
          raise
        end

        def fetch(event_id)
          events.where(id: event_id).map_with(:serialized_record_mapper).one!
        end

        def read(direction, stream, from: :head, limit: nil)
          order, operator = {
            forward:  [:asc, :>],
            backward: [:desc, :<]
          }[direction]

          raise ArgumentError, 'Direction must be :forward or :backward' if order.nil?

          query = events_for(stream, order).limit(limit)
          query = query.where(
                    stream_entries[:id].public_send(operator, fetch_stream_id_for(stream, from))
                  ) unless from.equal?(:head)

          query.to_a

        rescue ::ROM::TupleCountMismatchError
          raise EventNotFound.new(from)
        end

      private

        def events_for(stream, direction)
          order_columns = %i[position id]
          order_columns.delete(:position) if stream.global?

          events
            .join(stream_entries)
            .where(stream_entries[:stream].in(stream.name))
            .order { |r| order_columns.map { |c| r[:stream_entries][c].public_send(direction) } }
            .map_with(:serialized_record_mapper)
        end

        def fetch_stream_id_for(stream, event_id)
          stream_entries.where(stream: stream.name, event_id: event_id).select(:id).one![:id]
        end

        def compute_position(version, offset)
          version + offset + POSITION_SHIFT if version
        end
      end
    end
  end
end
