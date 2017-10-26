require 'active_record'

module RailsEventStoreActiveRecord
  class LegacyEventRepository
    GLOBAL_STREAM = 'all'.freeze

    class LegacyEvent < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = 'event_store_events'
      serialize :metadata
      serialize :data
    end

    private_constant :LegacyEvent
    private_constant :GLOBAL_STREAM

    def append_to_stream(events, stream_name, expected_version)
      validate_expected_version_is_not_auto(expected_version)

      case expected_version
      when :none
        validate_stream_is_empty(stream_name)
      when :any
      when Integer
        validate_expected_version_number(expected_version, stream_name)
      else
        raise RubyEventStore::InvalidExpectedVersion
      end

      normalize_to_array(events).each do |event|
        data = event.to_h.merge!(stream: stream_name, event_type: event.class)
        LegacyEvent.create!(data)
      end
      self
    rescue ActiveRecord::RecordNotUnique
      raise RubyEventStore::EventDuplicatedInStream
    end

    def delete_stream(stream_name)
      LegacyEvent.where({stream: stream_name}).update_all(stream: GLOBAL_STREAM)
    end

    def has_event?(event_id)
      LegacyEvent.exists?(event_id: event_id)
    end

    def last_stream_event(stream_name)
      build_event_entity(LegacyEvent.where(stream: stream_name).last)
    end

    def read_events_forward(stream_name, start_event_id, count)
      stream = LegacyEvent.where(stream: stream_name)
      unless start_event_id.equal?(:head)
        starting_event = LegacyEvent.find_by(event_id: start_event_id)
        stream = stream.where('id > ?', starting_event)
      end

      stream.order('id ASC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_events_backward(stream_name, start_event_id, count)
      stream = LegacyEvent.where(stream: stream_name)
      unless start_event_id.equal?(:head)
        starting_event = LegacyEvent.find_by(event_id: start_event_id)
        stream = stream.where('id < ?', starting_event)
      end

      stream.order('id DESC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_stream_events_forward(stream_name)
      LegacyEvent.where(stream: stream_name).order('id ASC')
        .map(&method(:build_event_entity))
    end

    def read_stream_events_backward(stream_name)
      LegacyEvent.where(stream: stream_name).order('id DESC')
        .map(&method(:build_event_entity))
    end

    def read_all_streams_forward(start_event_id, count)
      stream = LegacyEvent
      unless start_event_id.equal?(:head)
        starting_event = LegacyEvent.find_by(event_id: start_event_id)
        stream = stream.where('id > ?', starting_event)
      end

      stream.order('id ASC').limit(count)
        .map(&method(:build_event_entity))
    end

    def read_all_streams_backward(start_event_id, count)
      stream = LegacyEvent
      unless start_event_id.equal?(:head)
        starting_event = LegacyEvent.find_by(event_id: start_event_id)
        stream = stream.where('id < ?', starting_event)
      end

      stream.order('id DESC').limit(count)
        .map(&method(:build_event_entity))
    end

    private

    def normalize_to_array(events)
      [*events]
    end

    def build_event_entity(record)
      return nil unless record
      record.event_type.constantize.new(
        event_id: record.event_id,
        metadata: record.metadata,
        data: record.data
      )
    end

    def last_stream_version(stream_name)
      LegacyEvent.where(stream: stream_name).count - 1
    end

    def stream_non_empty?(stream_name)
      LegacyEvent.where(stream: stream_name).exists?
    end

    def validate_stream_is_empty(stream_name)
      raise RubyEventStore::WrongExpectedEventVersion if stream_non_empty?(stream_name)
    end

    def validate_expected_version_number(expected_version, stream_name)
      raise RubyEventStore::WrongExpectedEventVersion unless last_stream_version(stream_name).equal?(expected_version)
    end

    def validate_expected_version_is_not_auto(expected_version)
      raise RubyEventStore::InvalidExpectedVersion, ":auto mode is not supported by LegacyEventRepository" if expected_version.equal?(:auto)
    end

  end
end
