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
  
        ### Reader interface
  
        def all
          ([GLOBAL_STREAM] + event_streams.distinct.select(:stream).pluck(:stream))
            .uniq
            .map(&Stream.method(:new))
        end
      end
    end
  end
end
