# frozen_string_literal: true

module RubyEventStore
  module ROM
    module SQL
      module Relations
        class Events < ::ROM::Relation[:sql]
          schema(:event_store_events, as: :events, infer: true) do
            attribute :event_id, ::ROM::Types::String
            attribute :data, RubyEventStore::ROM::Types::RecordSerializer,
                      read: RubyEventStore::ROM::Types::RecordDeserializer
            attribute :metadata, RubyEventStore::ROM::Types::RecordSerializer,
                      read: RubyEventStore::ROM::Types::RecordDeserializer
            attribute :created_at, RubyEventStore::ROM::Types::DateTime
            attribute :valid_at, RubyEventStore::ROM::Types::DateTime

            primary_key :event_id
          end

          alias take limit

          def create_changeset(tuples)
            events.changeset(Changesets::CreateEvents, tuples)
          end

          def update_changeset(tuples)
            events.changeset(Changesets::UpdateEvents, tuples)
          end

          def by_event_id(event_id)
            where(event_id: event_id)
          end

          def by_event_type(types)
            where(event_type: types)
          end

          def newer_than(time)
            where { |r| r.events[:created_at] > time.localtime }
          end

          def newer_than_or_equal(time)
            where { |r| r.events[:created_at] >= time.localtime }
          end

          def older_than(time)
            where { |r| r.events[:created_at] < time.localtime }
          end

          def older_than_or_equal(time)
            where { |r| r.events[:created_at] <= time.localtime }
          end

          DIRECTION_MAP = {
            forward: %i[asc > <],
            backward: %i[desc < >]
          }.freeze

          def ordered(direction, offset_entry_id = nil, stop_entry_id = nil, time_sort_by = nil)
            order, operator_offset, operator_stop = DIRECTION_MAP[direction]

            raise ArgumentError, 'Direction must be :forward or :backward' if order.nil?

            event_order_columns = [:id]

            case time_sort_by
            when :as_at
              event_order_columns.unshift :created_at
            when :as_of
              event_order_columns.unshift :valid_at
            end

            query = self
            query = query.where { id.public_send(operator_offset, offset_entry_id) } if offset_entry_id
            query = query.where { id.public_send(operator_stop, stop_entry_id) } if stop_entry_id

            query.order(*event_order_columns.map { |c| events[c].public_send(order) })
          end
        end
      end
    end
  end
end
