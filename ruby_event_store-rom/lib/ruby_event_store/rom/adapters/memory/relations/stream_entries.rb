module RubyEventStore
  module ROM
    module Memory
      module Relations
        class StreamEntries < ::ROM::Relation[:memory]
          schema(:stream_entries) do
            attribute :id, ::ROM::Types::Int.meta(primary_key: true).default { RubyEventStore::ROM::Memory.fetch_next_id }
            attribute :stream, ::ROM::Types::String
            attribute :position, ::ROM::Types::Int.optional
            attribute :event_id, ::ROM::Types::String.meta(foreign_key: true, relation: :events)  

            associations do
              belongs_to :events, as: :event, foreign_key: :event_id, override: true, view: :for_stream_entries
            end
          end

          SERIALIZED_GLOBAL_STREAM_NAME = 'all'.freeze

          def take(num)
            return self unless num
            super
          end
          
          def insert(tuple)
            verify_uniquness!(tuple)
            super
          end
          
          def by_stream(stream)
            restrict(stream: stream.name)
          end
  
          def by_stream_and_event_id(stream, event_id)
            restrict(stream: stream.name, event_id: event_id).one!
          end
  
          def max_position(stream)
            new(by_stream(stream).order(:position).dataset.reverse).take(1).one
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

          def verify_uniquness!(tuple)
            stream = tuple[:stream]
            attrs = %i[position event_id]
            attrs.delete(:position) if Stream.new(stream).global?

            attrs.each do |key|
              next if key == :position && tuple[key].nil?
              next if restrict(:stream => stream, key => tuple[key]).to_a.none?

              raise TupleUniquenessError.new("Uniquness violated for: stream and #{key}")
            end
          end
        end
      end
    end
  end
end
