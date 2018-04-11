module RubyEventStore
  module ROM
    module Repositories
      class StreamEntries < ::ROM::Repository[:stream_entries]
        # struct_namespace Entities

        ### Writer interface

        def create(stream, event_id, position: nil)
          stream_entries.changeset(:create, {
            stream: stream.name,
            event_id: event_id,
            position: position
          }).commit
        end
  
        def delete(stream)
          stream_entries.where(stream: stream.name).command(:delete).call
        end
      end
    end
  end
end
