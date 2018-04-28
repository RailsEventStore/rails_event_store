module RubyEventStore
  module ROM
    module Memory
      module Relations
        class Events < ::ROM::Relation[:memory]
          schema(:events) do
            attribute :id, ::ROM::Types::String.meta(primary_key: true)
            attribute :event_type, ::ROM::Types::String
            attribute :metadata, ::ROM::Types::String.optional
            attribute :data, ::ROM::Types::String
            attribute :created_at, ::ROM::Types::DateTime.default { Time.now }
          end

          def insert(tuple)
            verify_uniquness!(tuple)
            super
          end
          
          def for_stream_entries(_assoc, stream_entries)
            restrict(id: stream_entries.map { |e| e[:event_id] })
          end
    
          def by_pk(id)
            restrict(id: id)
          end

          def exist?
            one?
          end

          def pluck(name)
            map { |e| e[name] }
          end
      
        private

          def verify_uniquness!(tuple)
            return unless by_pk(tuple[:id]).exist?
            raise TupleUniquenessError.for_event_id(tuple[:id])
          end
        end
      end
    end
  end
end
