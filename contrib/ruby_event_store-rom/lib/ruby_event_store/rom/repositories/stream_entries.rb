# frozen_string_literal: true

require_relative '../mappers/stream_entry_to_serialized_record'
require_relative '../changesets/create_stream_entries'

module RubyEventStore
  module ROM
    module Repositories
      class StreamEntries < ::ROM::Repository[:stream_entries]
        POSITION_SHIFT = 1

        def create_changeset(event_ids, stream, resolved_version)
          tuples = []

          event_ids.each_with_index do |event_id, index|
            unless stream.global?
              tuples << {
                stream: stream.name,
                position: resolved_version && resolved_version + index + POSITION_SHIFT,
                event_id: event_id
              }
            end
          end

          stream_entries.create_changeset(tuples)
        end

        def delete(stream)
          stream_entries.by_stream(stream).command(:delete).call
        end

        def resolve_version(stream, expected_version)
          expected_version.resolve_for(stream, lambda { |_stream|
            (stream_entries.max_position(stream) || {})[:position]
          })
        end

        def streams_of(event_id)
          stream_entries.by_event_id(event_id).map { |e| e[:stream] }
        end
      end
    end
  end
end
