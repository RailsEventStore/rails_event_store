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

          def create_changeset(tuples)
            changeset(ROM::Changesets::CreateStreamEntries, tuples)
          end

          def by_stream(stream)
            where(stream: stream.name)
          end

          def by_event_id(event_id)
            where(event_id: event_id)
          end

          def by_event_type(types)
            join(:events).where(event_type: types)
          end

          def by_stream_and_event_id(stream, event_id)
            where(stream: stream.name, event_id: event_id).one!
          end

          def max_position(stream)
            by_stream(stream).select(:position).order(Sequel.desc(:position)).first
          end

          def newer_than(time)
            join(:events).where { |r| r.events[:created_at] > time.localtime }
          end

          def newer_than_or_equal(time)
            join(:events).where { |r| r.events[:created_at] >= time.localtime }
          end

          def older_than(time)
            join(:events).where { |r| r.events[:created_at] < time.localtime }
          end

          def older_than_or_equal(time)
            join(:events).where { |r| r.events[:created_at] <= time.localtime }
          end

          DIRECTION_MAP = {
            forward: %i[asc > <],
            backward: %i[desc < >]
          }.freeze

          def ordered(direction, stream, offset_entry_id = nil, stop_entry_id = nil, time_sort_by = nil)
            order, operator_offset, operator_stop = DIRECTION_MAP[direction]

            raise ArgumentError, 'Direction must be :forward or :backward' if order.nil?

            event_order_columns  = []
            stream_order_columns = %i[position id]
            stream_order_columns.delete(:position) if stream.global?

            case time_sort_by
            when :as_at
              event_order_columns.unshift :created_at
            when :as_of
              event_order_columns.unshift :valid_at
            end

            query = by_stream(stream)
            query = query.where { id.public_send(operator_offset, offset_entry_id) } if offset_entry_id
            query = query.where { id.public_send(operator_stop, stop_entry_id) } if stop_entry_id

            if event_order_columns.empty?
              query.order { |r| stream_order_columns.map { |c| r[:stream_entries][c].public_send(order) } }
            else
              query.join(:events).order { |r| event_order_columns.map { |c| r.events[c].public_send(order) } }
            end
          end
        end
      end
    end
  end
end
