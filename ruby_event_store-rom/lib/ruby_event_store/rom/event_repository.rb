require 'ruby_event_store/rom/unit_of_work'
require 'forwardable'

module RubyEventStore
  module ROM
    class EventRepository
      extend Forwardable

      def_delegator :@rom, :handle_error, :guard_for
      def_delegators :@rom, :unit_of_work

      def initialize(rom: ROM.env)
        @rom = rom
        @events = Repositories::Events.new(rom.container)
        @stream_entries = Repositories::StreamEntries.new(rom.container)
      end

      def append_to_stream(events, stream, expected_version)
        events = normalize_to_array(events)
        event_ids = events.map(&:event_id)

        guard_for(:unique_violation) do
          unit_of_work do |changesets|
            # Create changesets inside transaction because
            # we want to find the last position (a.k.a. version)
            # again if the transaction is retried due to a
            # deadlock in MySQL
            changesets << @events.create_changeset(events)
            changesets << @stream_entries.create_changeset(event_ids, stream, expected_version, global_stream: true)
          end
        end

        self
      end

      def link_to_stream(event_ids, stream, expected_version)
        event_ids = normalize_to_array(event_ids)
        nonexistent_ids = @events.find_nonexistent_pks(event_ids)

        nonexistent_ids.each { |id| raise EventNotFound.new(id) }

        guard_for(:unique_violation) do
          @stream_entries.create_changeset(event_ids, stream, expected_version).commit
        end

        self
      end

      def delete_stream(stream)
        @stream_entries.delete(stream)
      end

      def has_event?(event_id)
        !! guard_for(:not_found, event_id, swallow: EventNotFound) do
          @events.exist?(event_id)
        end
      end

      def last_stream_event(stream)
        @events.read(
          :backward,
          stream,
          from: :head,
          limit: 1,
          batch_size: nil
        ).first
      end

      def read_event(event_id)
        guard_for(:not_found, event_id) do
          @events.by_id(event_id)
        end
      end

      def read(specification)
        raise ReservedInternalName if specification.stream_name.eql?(@stream_entries.stream_entries.class::SERIALIZED_GLOBAL_STREAM_NAME)

        @events.read(
          specification.direction,
          specification.stream,
          from: specification.start,
          limit: (specification.count if specification.limit?),
          batch_size: (specification.batch_size if specification.batched?)
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
