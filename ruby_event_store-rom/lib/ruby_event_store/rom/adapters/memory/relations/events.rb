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
          end

          def for_stream_entries(_assoc, stream_entries)
            restrict(id: stream_entries.map { |e| e[:event_id] })
          end
    
          def by_pk(id)
            restrict(id: id)
          end

          def exist?
            to_a.one?
          end

          def pluck(name)
            project(name).map { |e| e[name] }
          end
        end
      end
    end
  end
end
