# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Memory
      module Relations
        class Events < ::ROM::Relation[:memory]
          schema(:events) do
            attribute(:id, ::ROM::Types::Strict::Integer.default { RubyEventStore::ROM::Memory.fetch_next_id })
            attribute :event_id, ::ROM::Types::Strict::String.meta(primary_key: true)
            attribute :event_type, ::ROM::Types::Strict::String
            attribute :metadata, ::ROM::Types::Strict::String.optional
            attribute :data, ::ROM::Types::Strict::String
            attribute :created_at, RubyEventStore::ROM::Types::DateTime
            attribute :valid_at, RubyEventStore::ROM::Types::DateTime
          end

          def create_changeset(tuples)
            events.changeset(Changesets::CreateEvents, tuples)
          end

          def update_changeset(tuples)
            events.changeset(Changesets::UpdateEvents, tuples)
          end

          def insert(tuple)
            verify_uniquness!(tuple)
            super
          end

          def offset(num)
            num.zero? ? self : new(dataset.slice(num..-1) || [])
          end

          def for_stream_entries(_assoc, stream_entries)
            restrict(event_id: stream_entries.map { |e| e[:event_id] })
          end

          def by_event_id(event_id)
            restrict(event_id: event_id)
          end

          def by_event_type(event_type)
            restrict(event_type: event_type)
          end

          def exist?
            one?
          end

          def pluck(name)
            map { |e| e[name] }
          end

          def newer_than(time)
           restrict { |tuple| tuple[:created_at] > time.localtime }
          end

          def newer_than_or_equal(time)
            restrict { |tuple| tuple[:created_at] >= time.localtime }
          end

          def older_than(time)
            events.restrict { |tuple| tuple[:created_at] < time.localtime }
          end

          def older_than_or_equal(time)
            restrict { |tuple| tuple[:created_at] <= time.localtime }
          end

          DIRECTION_MAP = {
            forward: [false, :>, :<],
            backward: [true, :<, :>]
          }.freeze

          def ordered(direction, offset_entry_id = nil, stop_entry_id = nil, time_sort_by = nil)
            reverse, operator_offset, operator_stop = DIRECTION_MAP[direction]

            raise ArgumentError, 'Direction must be :forward or :backward' if order.nil?

            event_order_columns = [:id]

            case time_sort_by
            when :as_at
              event_order_columns.unshift :created_at
            when :as_of
              event_order_columns.unshift :valid_at
            end

            query = self
            query = query.restrict { |tuple| tuple[:id].public_send(operator_offset, offset_entry_id) } if offset_entry_id
            query = query.restrict { |tuple| tuple[:id].public_send(operator_stop, stop_entry_id) } if stop_entry_id
            query = new(query.dataset.sort_by { |tuple| event_order_columns.map { |c| tuple[c] } })
            query = new(query.dataset.reverse) if reverse
            query
          end

          private

          def verify_uniquness!(tuple)
            return unless by_event_id(tuple[:event_id]).exist?

            raise TupleUniquenessError.for_event_id(tuple[:event_id])
          end
        end
      end
    end
  end
end
