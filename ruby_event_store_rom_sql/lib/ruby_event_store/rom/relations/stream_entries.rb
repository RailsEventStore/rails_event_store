module RubyEventStore
  module ROM
    module Relations
      class StreamEntries < ::ROM::Relation[:sql]
        schema(:event_store_events_in_streams, as: :stream_entries, infer: true) do
          attribute :id, ::ROM::Types::Int.meta(primary_key: true)
          attribute :stream, ::ROM::Types::String
          attribute :position, ::ROM::Types::Int.optional
          attribute :event_id, ::ROM::Types::String.meta(foreign_key: true, relation: :events)
          attribute :created_at, ::ROM::Types::DateTime.default { Time.now.utc }

          associations do
            belongs_to :events, as: :event, foreign_key: :event_id
          end
        end
  
        # struct_namespace Entities
        # auto_struct true

        def by_stream(stream)
          where(stream: stream.name)
        end

        def by_stream_and_event_id(stream, event_id)
          where(stream: stream.name, event_id: event_id).one!
        end

        def max_position(stream)
          by_stream(stream).select(:position).order(Sequel.desc(:position)).first
        end

        DIRECTION_MAP = {
          forward:  [:asc,  :>],
          backward: [:desc, :<]
        }.freeze

        def ordered(direction, stream, offset_entry_id = nil)
          order, operator = DIRECTION_MAP[direction]

          raise ArgumentError, 'Direction must be :forward or :backward' if order.nil?

          order_columns = %i[position id]
          order_columns.delete(:position) if stream.global?
          
          query = by_stream(stream)
          query = query.where { id.public_send(operator, offset_entry_id) } if offset_entry_id
          query.order { |r| order_columns.map { |c| r[:stream_entries][c].public_send(order) } }
        end
      end
    end
  end
end
