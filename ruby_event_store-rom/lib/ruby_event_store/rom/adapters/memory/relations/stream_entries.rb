module RubyEventStore
  module ROM
    module Memory
      module Relations
        class StreamEntries < ::ROM::Relation[:memory]
          schema(:stream_entries) do
            attribute :id, ::ROM::Types::Strict::Int.meta(primary_key: true).default { RubyEventStore::ROM::Memory.fetch_next_id }
            attribute :stream, ::ROM::Types::Strict::String
            attribute :position, ::ROM::Types::Strict::Int.optional
            attribute :event_id, ::ROM::Types::Strict::String.meta(foreign_key: true, relation: :events)
            attribute :created_at, ::ROM::Types::Strict::Time.default { Time.now }

            associations do
              belongs_to :events, as: :event, foreign_key: :event_id, override: true, view: :for_stream_entries
            end
          end

          auto_struct true

          SERIALIZED_GLOBAL_STREAM_NAME = 'all'.freeze

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
            restrict(stream: normalize_stream_name(stream))
          end
  
          def by_stream_and_event_id(stream, event_id)
            restrict(stream: normalize_stream_name(stream), event_id: event_id).one!
          end
  
          def max_position(stream)
            new(by_stream(stream).order(:position).dataset.reverse).project(:position).take(1).one
          end
  
          DIRECTION_MAP = {
            forward:  [false,  :>],
            backward: [true, :<]
          }.freeze
  
          def ordered(direction, stream, offset_entry_id = nil)
            reverse, operator = DIRECTION_MAP[direction]
  
            raise ArgumentError, 'Direction must be :forward or :backward' if order.nil?
  
            order_columns = %i[position id]
            order_columns.delete(:position) if stream.global?
            
            query = by_stream(stream)
            query = query.restrict { |tuple| tuple[:id].public_send(operator, offset_entry_id) } if offset_entry_id
            query = query.order(*order_columns)
            query = new(query.dataset.reverse) if reverse

            query
          end
        
        private

          # Verifies uniqueness of [stream, event_id] and [stream, position]
          def verify_uniquness!(tuple)
            stream = tuple[:stream]
            attrs = %i[position event_id]
            attrs.delete(:position) if Stream.new(stream).global?

            attrs.each do |key|
              next if key == :position && tuple[key].nil?
              next if restrict(:stream => stream, key => tuple[key]).to_a.none?

              raise TupleUniquenessError.send(:"for_stream_and_#{key}", stream, tuple[key])
            end
          end

          def normalize_stream_name(stream)
            stream.global? ? SERIALIZED_GLOBAL_STREAM_NAME : stream.name
          end
        end
      end
    end
  end
end
