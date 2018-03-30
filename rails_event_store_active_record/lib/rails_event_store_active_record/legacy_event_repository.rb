require 'active_record'

module RailsEventStoreActiveRecord
  class LegacyEventRepository
    class LegacyEvent < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = 'event_store_events'
      serialize :metadata
      serialize :data
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
      LegacyEvent.where({stream: stream.name}).update_all(stream: RubyEventStore::GLOBAL_STREAM)
    end

    def has_event?(event_id)
      LegacyEvent.exists?(event_id: event_id)
    end

    def last_stream_event(stream)
      build_event_entity(LegacyEvent.where(stream: stream.name).last)
    end

    def read_events_forward(stream, start_event_id, count)
      raise ReservedInternalName if stream.name.eql?("all")

      events = LegacyEvent.where(stream: stream.name)
      unless start_event_id.equal?(:head)
        starting_event = LegacyEvent.find_by(event_id: start_event_id)
        events = events.where('id > ?', starting_event)
      end

      events.order('id ASC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_events_backward(stream, start_event_id, count)
      raise ReservedInternalName if stream.name.eql?("all")

      events = LegacyEvent.where(stream: stream.name)
      unless start_event_id.equal?(:head)
        starting_event = LegacyEvent.find_by(event_id: start_event_id)
        events = events.where('id < ?', starting_event)
      end

      events.order('id DESC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_stream_events_forward(stream)
      raise ReservedInternalName if stream.name.eql?("all")

      LegacyEvent.where(stream: stream.name).order('id ASC')
        .map(&method(:build_event_entity))
    end

    def read_stream_events_backward(stream)
      raise ReservedInternalName if stream.name.eql?("all")

      LegacyEvent.where(stream: stream.name).order('id DESC')
        .map(&method(:build_event_entity))
    end

    def read_all_streams_forward(start_event_id, count)
      events = LegacyEvent
      unless start_event_id.equal?(:head)
        starting_event = LegacyEvent.find_by(event_id: start_event_id)
        events = events.where('id > ?', starting_event)
      end

      events.order('id ASC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_all_streams_backward(start_event_id, count)
      events = LegacyEvent
      unless start_event_id.equal?(:head)
        starting_event = LegacyEvent.find_by(event_id: start_event_id)
        events = events.where('id < ?', starting_event)
      end

      events.order('id DESC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_event(event_id)
      build_event_entity(LegacyEvent.find_by(event_id: event_id)) or raise RubyEventStore::EventNotFound.new(event_id)
    end

    def read(_)
      [].each
    end

    private

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
