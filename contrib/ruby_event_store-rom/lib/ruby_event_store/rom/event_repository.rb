# frozen_string_literal: true

require_relative 'unit_of_work'

module RubyEventStore
  module ROM
    class EventRepository
      def initialize(rom: ROM.env, serializer:)
        raise ArgumentError, 'Must specify rom' unless rom && rom.instance_of?(Env)

        @rom            = rom
        @serializer     = serializer
        @events         = Repositories::Events.new(rom.rom_container)
        @stream_entries = Repositories::StreamEntries.new(rom.rom_container)
      end

      def append_to_stream(records, stream, expected_version)
        serialized_records = Array(records).map { |record| record.serialize(@serializer) }
        event_ids          = serialized_records.map(&:event_id)

        @rom.handle_error(:unique_violation) do
          @rom.unit_of_work do |changesets|
            changesets << @events.create_changeset(serialized_records)
            changesets << @stream_entries.create_changeset(
              event_ids,
              stream,
              @stream_entries.resolve_version(stream, expected_version)
            )
          end
        end

        self
      end

      def link_to_stream(event_ids, stream, expected_version)
        event_ids = Array(event_ids)
        validate_event_ids(event_ids)

        @rom.handle_error(:unique_violation) do
          @rom.unit_of_work do |changesets|
            changesets << @stream_entries.create_changeset(
              event_ids,
              stream,
              @stream_entries.resolve_version(stream, expected_version)
            )
          end
        end

        self
      end

      def position_in_stream(event_id, stream)
        @stream_entries.position_in_stream(event_id, stream)
      end

      def global_position(event_id)
        @events.global_position(event_id)
      end

      def delete_stream(stream)
        @stream_entries.delete(stream)
      end

      def has_event?(event_id)
        @rom.handle_error(:not_found, event_id, swallow: EventNotFound) { @events.exist?(event_id) } || false
      end

      def last_stream_event(stream)
        @events.last_stream_event(stream, @serializer)
      end

      def read(specification)
        @events.read(specification, @serializer)
      end

      def count(specification)
        @events.count(specification)
      end

      def update_messages(records)
        validate_event_ids(records.map(&:event_id))

        @rom.unit_of_work do |changesets|
          serialized_records = records.map { |record| record.serialize(@serializer) }
          changesets << @events.update_changeset(serialized_records)
        end
      end

      def streams_of(event_id)
        @stream_entries
          .streams_of(event_id)
          .map { |name| Stream.new(name) }
      end

      private

      def validate_event_ids(event_ids)
        @events
          .find_nonexistent_pks(event_ids)
          .each { |id| raise EventNotFound, id }
      end
    end
  end
end
