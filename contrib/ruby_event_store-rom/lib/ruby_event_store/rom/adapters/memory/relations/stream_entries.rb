# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Memory
      module Relations
        class StreamEntries < ::ROM::Relation[:memory]
          schema(:stream_entries) do
            attribute(:id, ::ROM::Types::Strict::Integer.default { RubyEventStore::ROM::Memory.fetch_next_id })
            attribute :stream, ::ROM::Types::Strict::String
            attribute :position, ::ROM::Types::Strict::Integer.optional
            attribute :event_id, ::ROM::Types::Strict::String.meta(foreign_key: true, relation: :events)
            attribute :created_at, RubyEventStore::ROM::Types::DateTime

            associations do
              belongs_to :events, as: :event, foreign_key: :event_id, override: true, view: :for_stream_entries
            end
          end

          def for_events(events)
            restrict(event_id: events.map { |e| e[:event_id] })
          end

          auto_struct true

          def create_changeset(tuples)
            changeset(Changesets::CreateStreamEntries, tuples)
          end

          def offset(num)
            num.zero? ? self : new(dataset.slice(num..-1) || [])
          end

          def take(num)
            num.nil? ? self : super
          end

          def insert(tuple)
            verify_uniquness!(tuple)
            super
          end

          def delete(tuple)
            super tuple.to_h
          end

          def by_stream(stream)
            restrict(stream: stream.name)
          end

          def by_event_id(event_id)
            restrict(event_id: event_id)
          end

          def by_event_type(types)
            for_events(events.restrict(event_type: Array(types)))
          end

          def by_stream_and_event_id(stream, event_id)
            restrict(stream: stream.name, event_id: event_id).one!
          end

          def max_position(stream)
            new(by_stream(stream).order(:position).dataset.reverse).project(:position).take(1).one
          end

          def newer_than(time)
            for_events(events.restrict { |tuple| tuple[:created_at] > time.localtime })
          end

          def newer_than_or_equal(time)
            for_events(events.restrict { |tuple| tuple[:created_at] >= time.localtime })
          end

          def older_than(time)
            for_events(events.restrict { |tuple| tuple[:created_at] < time.localtime })
          end

          def older_than_or_equal(time)
            for_events(events.restrict { |tuple| tuple[:created_at] <= time.localtime })
          end

          DIRECTION_MAP = {
            forward: [false, :>, :<],
            backward: [true, :<, :>]
          }.freeze

          def ordered(direction, stream, offset_entry_id = nil, stop_entry_id = nil, time_sort_by = nil)
            reverse, operator_offset, operator_stop = DIRECTION_MAP[direction]

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
            query = query.restrict { |tuple| tuple[:id].public_send(operator_offset, offset_entry_id) } if offset_entry_id
            query = query.restrict { |tuple| tuple[:id].public_send(operator_stop, stop_entry_id) } if stop_entry_id

            if event_order_columns.empty?
              query = query.order(*stream_order_columns)
            else
              query = new(query.dataset.sort_by { |r| event_order_columns.map { |c| events.by_event_id(r[:event_id]).one[c] }})
            end

            query = new(query.dataset.reverse) if reverse
            query
          end

          private

          # Verifies uniqueness of [stream, event_id] and [stream, position]
          def verify_uniquness!(tuple)
            stream = tuple[:stream]
            attrs  = %i[position event_id]

            attrs.each do |key|
              next if key == :position && tuple[key].nil?
              next if restrict(:stream => stream, key => tuple.fetch(key)).none?

              raise TupleUniquenessError.public_send(:"for_stream_and_#{key}", stream, tuple.fetch(key))
            end
          end
        end
      end
    end
  end
end
