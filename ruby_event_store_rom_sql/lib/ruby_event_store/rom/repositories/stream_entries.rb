require_relative '../mappers/stream_entry_to_serialized_record'

module RubyEventStore
  module ROM
    module Repositories
      class StreamEntries < ::ROM::Repository[:stream_entries]
        # struct_namespace Entities

        ### Writer interface

        POSITION_SHIFT = 1.freeze

        def create(event_ids, stream, expected_version = ExpectedVersion.any, global_stream: nil)
          resolved_version = expected_version.resolve_for(stream, ->(stream) {
            (stream_entries.max_position(stream) || {})[:position]
          })

          tuples = []

          event_ids.each_with_index do |event_id, index|
            tuples << {
              stream: stream.name,
              position: resolved_version && resolved_version + index + POSITION_SHIFT,
              event_id: event_id
            } unless stream.global?

            tuples << {
              stream: GLOBAL_STREAM,
              event_id: event_id
            } if global_stream
          end

          stream_entries.changeset(:create, tuples).commit
        end

        def delete(stream)
          stream_entries.by_stream(stream).command(:delete, result: :many).call
        end
      end
    end
  end
end
