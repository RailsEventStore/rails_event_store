require 'active_record'

module RailsEventStoreActiveRecord
  module Legacy
    class EventRepository
      SERIALIZED_GLOBAL_STREAM_NAME = 'all'.freeze

      class LegacyEvent < ::ActiveRecord::Base
        self.primary_key = :id
        self.table_name = 'event_store_events'
      end

      private_constant :LegacyEvent

      def initialize
        warn <<-MSG
`RailsEventStoreActiveRecord::LegacyEventRepository` has been deprecated.

Please migrate to new database schema and use `RailsEventStoreActiveRecord::EventRepository`
instead:

  rails generate rails_event_store_active_record:v1_v2_migration

        MSG
      end

      def append_to_stream(events, stream, expected_version)
        validate_unsupported_expected_version(expected_version)
        validate_stream_is_empty(stream) if expected_version.none?
        validate_expected_version_number(expected_version, stream) if Integer === expected_version.version

        normalize_to_array(events).each do |event|
          data = event.to_h
          data[:stream] = stream.name
          LegacyEvent.create!(data)
        end
        self
      rescue ActiveRecord::RecordNotUnique
        raise RubyEventStore::EventDuplicatedInStream
      end

      def link_to_stream(_event_ids, _stream, _expected_version)
        raise RubyEventStore::NotSupported
      end

      def delete_stream(stream)
        LegacyEvent.where({stream: stream.name}).update_all(stream: SERIALIZED_GLOBAL_STREAM_NAME)
      end

      def has_event?(event_id)
        LegacyEvent.exists?(event_id: event_id)
      end

      def last_stream_event(stream)
        build_event_entity(LegacyEvent.where(stream: stream.name).last)
      end

      def read(spec)
        stream = LegacyEvent.order(id: order(spec))
        stream = stream.where(event_id: spec.with_ids) if spec.with_ids?
        stream = stream.where(event_type: spec.with_types) if spec.with_types?
        stream = stream.limit(spec.limit) if spec.limit?
        stream = stream.where(start_condition(spec)) unless spec.head?
        stream = stream.where(stream: spec.stream.name) unless spec.stream.global?

        if spec.batched?
          batch_reader = ->(offset, limit) { stream.offset(offset).limit(limit).map(&method(:build_event_entity)) }
          RubyEventStore::BatchEnumerator.new(spec.batch_size, spec.limit, batch_reader).each
        elsif spec.first?
          build_event_entity(stream.first)
        elsif spec.last?
          build_event_entity(stream.last)
        else
          stream.map(&method(:build_event_entity)).each
        end
      end

      def streams_of(event_id)
        LegacyEvent.where(event_id: event_id)
          .pluck(:stream)
          .map{|name| RubyEventStore::Stream.new(name)}
      end

      private

      def start_condition(specification)
        event_record =
          LegacyEvent.find_by!(event_id: specification.start)
        condition = specification.forward? ? 'id > ?' : 'id < ?'
        [condition, event_record]
      end

      def order(spec)
        spec.forward? ? 'ASC' : 'DESC'
      end


      def normalize_to_array(events)
        return events if events.is_a?(Enumerable)
        [events]
      end

      def build_event_entity(record)
        return nil unless record
        RubyEventStore::SerializedRecord.new(
          event_id: record.event_id,
          metadata: record.metadata,
          data: record.data,
          event_type: record.event_type,
        )
      end

      def last_stream_version(stream)
        LegacyEvent.where(stream: stream.name).count - 1
      end

      def stream_non_empty?(stream)
        LegacyEvent.where(stream: stream.name).exists?
      end

      def validate_stream_is_empty(stream)
        raise RubyEventStore::WrongExpectedEventVersion if stream_non_empty?(stream)
      end

      def validate_expected_version_number(expected_version, stream)
        raise RubyEventStore::WrongExpectedEventVersion unless last_stream_version(stream).equal?(expected_version.version)
      end

      def validate_unsupported_expected_version(expected_version)
        raise RubyEventStore::InvalidExpectedVersion, ":auto mode is not supported by LegacyEventRepository" if expected_version.auto?
      end
    end
  end
end
