require_relative '../mappers/stream_entry_to_serialized_record'

module RubyEventStore
  module ROM
    module Repositories
      class StreamEntries < ::ROM::Repository[:stream_entries]
        class Create < ::ROM::Changeset::Create
          map do |tuple|
            Hash(created_at: Time.now).merge(tuple)
          end
        end

        POSITION_SHIFT = 1.freeze

        def create_changeset(event_ids, stream, resolved_version, global_stream: nil)
          tuples = []
          
          event_ids.each_with_index do |event_id, index|
            tuples << {
              stream: stream.name,
              position: resolved_version && resolved_version + index + POSITION_SHIFT,
              event_id: event_id
             } unless stream.global?

             tuples << {
              stream: stream_entries.class::SERIALIZED_GLOBAL_STREAM_NAME,
              position: nil,
              event_id: event_id
            } if global_stream
          end

          stream_entries.changeset(Create, tuples)
        end

        def delete(stream)
          delete_changeset(stream).commit
        end

        def delete_changeset(stream)
          stream_entries.by_stream(stream).changeset(:delete)
        end

        def resolve_version(stream, expected_version)
          expected_version.resolve_for(stream, ->(_stream) {
            (stream_entries.max_position(stream) || {})[:position]
          })
        end
      end
    end
  end
end
