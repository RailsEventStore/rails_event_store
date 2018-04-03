module RubyEventStoreRomSql
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
  
        # TODO: Replace with Sequel::Dataset#import(columns, values, opts) ?
        # See: http://www.rubydoc.info/github/jeremyevans/sequel/Sequel%2FDataset%3Aimport
        def import(tuples)
          event_streams.changeset(:create, tuples).commit
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
