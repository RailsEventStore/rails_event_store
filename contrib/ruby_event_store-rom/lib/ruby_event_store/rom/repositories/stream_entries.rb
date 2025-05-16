# frozen_string_literal: true

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
                event_id: event_id,
              }
            end
          end

          stream_entries.create_changeset(tuples)
        end

        def delete(stream)
          stream_entries.by_stream(stream).command(:delete).call
        end

        def resolve_version(stream, expected_version)
          expected_version.resolve_for(
            stream,
            lambda { |_stream| (stream_entries.max_position(stream) || {})[:position] },
          )
        end

        def streams_of(event_id)
          stream_entries.by_event_id(event_id).map { |e| e[:stream] }
        end

        def position_in_stream(event_id, stream)
          record = stream_entries.by_stream(stream).by_event_id(event_id).one
          raise EventNotFoundInStream if record.nil?
          record.position
        end

        def event_in_stream?(event_id, stream)
          stream_entries.by_stream(stream).by_event_id(event_id).exist?
        end
      end
    end
  end
end
