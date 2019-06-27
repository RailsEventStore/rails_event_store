# frozen_string_literal: true

module RubyEventStore
  module ROM
    module SQL
      module Relations
        class StreamEntries < ::ROM::Relation[:sql]
          schema(:event_store_events_in_streams, as: :stream_entries, infer: true) do
            attribute :created_at, RubyEventStore::ROM::Types::DateTime

            associations do
              belongs_to :events, as: :event, foreign_key: :event_id
            end
          end

          alias take limit

          SERIALIZED_GLOBAL_STREAM_NAME = 'all'.freeze

          def create_changeset(tuples)
            changeset(ROM::Changesets::CreateStreamEntries, tuples)
          end

          def by_stream(stream)
            where(stream: normalize_stream_name(stream))
          end

          def by_event_id(event_id)
            where(event_id: event_id)
          end

          def by_event_type(types)
            join(:events).where(event_type: types)
          end

          def by_stream_and_event_id(stream, event_id)
            where(stream: normalize_stream_name(stream), event_id: event_id).one!
          end

          def max_position(stream)
            by_stream(stream).select(:position).order(Sequel.desc(:position)).first
          end

          DIRECTION_MAP = {
            forward: %i[asc > <],
            backward: %i[desc < >]
          }.freeze

          def ordered(direction, stream, offset_entry_id = nil, stop_entry_id = nil)
            order, operator_offset, operator_stop = DIRECTION_MAP[direction]

            raise ArgumentError, 'Direction must be :forward or :backward' if order.nil?

            order_columns = %i[position id]
            order_columns.delete(:position) if stream.global?

            query = by_stream(stream)
            query = query.where { id.public_send(operator_offset, offset_entry_id) } if offset_entry_id
            query = query.where { id.public_send(operator_stop, stop_entry_id) } if stop_entry_id
            query.order { |r| order_columns.map { |c| r[:stream_entries][c].public_send(order) } }
          end

          private

          def normalize_stream_name(stream)
            stream.global? ? SERIALIZED_GLOBAL_STREAM_NAME : stream.name
          end
        end
      end
    end
  end
end
