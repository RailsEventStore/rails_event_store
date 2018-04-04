module RubyEventStore
  module ROM
    module Repositories
      class EventStreams < ::ROM::Repository[:event_streams]
        # struct_namespace Entities

        ### Writer interface

        def create(stream_name, event_id, position: nil)
          event_streams.changeset(:create, {
            stream: stream_name,
            event_id: event_id,
            position: position
          }).commit
        end
  
        def delete(stream_name)
          event_streams.where(stream: stream_name).command(:delete).call
        end
  
        ### Reader interface
  
        def all
          ([RubyEventStore::GLOBAL_STREAM] + event_streams.select(:stream).distinct.pluck(:stream))
            .uniq
            .map(&RubyEventStore::Stream.method(:new))
        end
      end
    end
  end
end
