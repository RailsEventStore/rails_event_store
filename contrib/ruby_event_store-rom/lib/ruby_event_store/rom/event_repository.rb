# frozen_string_literal: true

module RubyEventStore
  module ROM
    class EventRepository
      def initialize(rom:, serializer:)
        @serializer = serializer
        @events = Repositories::Events.new(rom)
        @stream_entries = Repositories::StreamEntries.new(rom)
        @unit_of_work = UnitOfWork.new(rom.gateways.fetch(:default))
      end

      def append_to_stream(records, stream, expected_version)
        serialized_records = records.map { |record| record.serialize(@serializer) }
        event_ids = records.map(&:event_id)

        handle_unique_violation do
          @unit_of_work.call do |changesets|
            changesets << @events.create_changeset(serialized_records)
            changesets <<
              @stream_entries.create_changeset(
                event_ids,
                stream,
                @stream_entries.resolve_version(stream, expected_version)
              )
          end
        end

        self
      end

      def link_to_stream(event_ids, stream, expected_version)
        validate_event_ids(event_ids)

        handle_unique_violation do
          @unit_of_work.call do |changesets|
            changesets <<
              @stream_entries.create_changeset(
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

      def event_in_stream?(event_id, stream)
        @stream_entries.event_in_stream?(event_id, stream)
      end

      def delete_stream(stream)
        @stream_entries.delete(stream)
      end

      def has_event?(event_id)
        @events.exist?(event_id)
      rescue Sequel::DatabaseError => doh
        raise doh unless /PG::InvalidTextRepresentation.*uuid/.match?(doh.message)
        false
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

        @unit_of_work.call do |changesets|
          serialized_records = records.map { |record| record.serialize(@serializer) }
          changesets << @events.update_changeset(serialized_records)
        end
      end

      def streams_of(event_id)
        @stream_entries.streams_of(event_id).map { |name| Stream.new(name) }
      end

      private

      def validate_event_ids(event_ids)
        @events.find_nonexistent_pks(event_ids).each { |id| raise EventNotFound, id }
      end

      def handle_unique_violation
        yield
      rescue ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation => doh
        raise ::RubyEventStore::EventDuplicatedInStream if IndexViolationDetector.new.detect(doh.message)
        raise ::RubyEventStore::WrongExpectedEventVersion
      end
    end
  end
end
