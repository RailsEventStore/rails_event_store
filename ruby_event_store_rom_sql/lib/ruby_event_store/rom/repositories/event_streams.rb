module RubyEventStore
  module ROM
    module Repositories
      class EventStreams < ::ROM::Repository[:event_streams]
        # struct_namespace Entities

        ### Writer interface

        def create(stream, event_id, position: nil)
          event_streams.changeset(:create, {
            stream: stream.name,
            event_id: event_id,
            position: position
          }).commit
        end
  
        def delete(stream)
          event_streams.where(stream: stream.name).command(:delete).call
        end
      end
    end
  end
end
