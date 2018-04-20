require 'ruby_event_store/rom/sql/index_violation_detector'
require 'ruby_event_store/rom/unit_of_work'

module RubyEventStore
  module ROM
    class EventRepository
      def initialize(rom: ROM.env)
        @rom = rom
        @events = Repositories::Events.new(rom.container)
        @stream_entries = Repositories::StreamEntries.new(rom.container)
      end

      def append_to_stream(events, stream, expected_version)
        events = normalize_to_array(events)
        event_ids = events.map(&:event_id)

        UnitOfWork.perform(@rom.container.gateways.fetch(:default)) do |session|
          session << @events.create_changeset(events)
          session << @stream_entries.create_changeset(event_ids, stream, expected_version, global_stream: true)
        end

        self
      rescue => ex
        @rom.handle_error(:unique_violation, ex)
      end

      def link_to_stream(event_ids, stream, expected_version)
        event_ids = normalize_to_array(event_ids)
        nonexistent_ids = @events.find_nonexistent_pks(event_ids)

        nonexistent_ids.each { |id| raise EventNotFound.new(id) }

        @stream_entries.create_changeset(event_ids, stream, expected_version).commit

        self
      rescue => ex
        @rom.handle_error(:unique_violation, ex)
      end

      def delete_stream(stream)
        @stream_entries.delete(stream)
      end

      def has_event?(event_id)
        @events.exist?(event_id)
      rescue => ex
        begin
          @rom.handle_error(:not_found, ex, event_id)
        rescue EventNotFound
          false
        end
      end

      def last_stream_event(stream)
        Specification.new(self)
          .stream(stream.name)
          .limit(1)
          .backward
          .each
          .first
      end

      def read_event(event_id)
        @events.by_id(event_id)
      rescue => ex
        @rom.handle_error(:not_found, ex, event_id)
      end

      def read(specification)
        raise ReservedInternalName if specification.stream_name.eql?(@stream_entries.stream_entries.class::SERIALIZED_GLOBAL_STREAM_NAME)

        @events.read(
          specification.direction,
          specification.stream,
          from: specification.start,
          limit: (specification.count if specification.limit?)
        )
      end

      private

      def normalize_to_array(events)
        return events if events.is_a?(Enumerable)
        [events]
      end
    end
  end
end
