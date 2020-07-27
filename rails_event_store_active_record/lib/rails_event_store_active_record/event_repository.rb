# frozen_string_literal: true

require 'activerecord-import'

module RailsEventStoreActiveRecord
  class EventRepository
    POSITION_SHIFT = 1
    SERIALIZED_GLOBAL_STREAM_NAME = "all".freeze

    def initialize
      @repo_reader = EventRepositoryReader.new
    end

    def append_to_stream(events, stream, expected_version)
      records = Array(events).map(&method(:build_event_record))
      add_to_stream(records, stream, expected_version, true) do
        Event.import(records)
      end
    end

    def link_to_stream(event_ids, stream, expected_version)
      event_ids = Array(event_ids)
      (event_ids - Event.where(id: event_ids).pluck(:id)).each do |id|
        raise RubyEventStore::EventNotFound.new(id)
      end
      add_to_stream(event_ids, stream, expected_version, nil)
    end

    def delete_stream(stream)
      EventInStream.where(stream: stream.name).delete_all
    end

    def has_event?(event_id)
      @repo_reader.has_event?(event_id)
    end

    def last_stream_event(stream)
      @repo_reader.last_stream_event(stream)
    end

    def read(specification)
      @repo_reader.read(specification)
    end

    def count(specification)
      @repo_reader.count(specification)
    end

    def update_messages(messages)
      hashes = messages.map(&:to_h)
      hashes.each{|h| h[:id] = h.delete(:event_id) }
      for_update = messages.map(&:event_id)
      start_transaction do
        existing = Event.where(id: for_update).pluck(:id)
        (for_update - existing).each{|id| raise RubyEventStore::EventNotFound.new(id) }
        Event.import(hashes, on_duplicate_key_update: [:data, :metadata, :event_type])
      end
    end

    def streams_of(event_id)
      EventInStream.where(event_id: event_id)
        .where.not(stream: SERIALIZED_GLOBAL_STREAM_NAME)
        .pluck(:stream)
        .map{|name| RubyEventStore::Stream.new(name)}
    end

    private

    def add_to_stream(collection, stream, expected_version, include_global)
      last_stream_version = ->(stream_) { EventInStream.where(stream: stream_.name).order("position DESC").first.try(:position) }
      resolved_version = expected_version.resolve_for(stream, last_stream_version)

      start_transaction do
        yield if block_given?
        in_stream = collection.flat_map.with_index do |event_or_id, index|
          position = compute_position(resolved_version, index)
          collection = []
          collection.unshift({
            stream: SERIALIZED_GLOBAL_STREAM_NAME,
            position: nil,
            event_id: event_or_id,
          }) if include_global
          collection.unshift({
            stream:   stream.name,
            position: position,
            event_id: event_or_id
          }) unless stream.global?
          collection
        end
        fill_ids(in_stream)
        EventInStream.import(in_stream)
      end
      self
    rescue ActiveRecord::RecordNotUnique => e
      raise_error(e)
    end

    def raise_error(e)
      if detect_index_violated(e.message)
        raise RubyEventStore::EventDuplicatedInStream
      end
      raise RubyEventStore::WrongExpectedEventVersion
    end

    def compute_position(resolved_version, index)
      unless resolved_version.nil?
        resolved_version + index + POSITION_SHIFT
      end
    end

    def detect_index_violated(message)
      IndexViolationDetector.new.detect(message)
    end

    def build_event_record(serialized_record)
      Event.new(
        id:         serialized_record.event_id,
        data:       serialized_record.data,
        metadata:   serialized_record.metadata,
        event_type: serialized_record.event_type
      )
    end

    # Overwritten in a sub-class
    def fill_ids(_in_stream)
    end

    def start_transaction(&block)
      ActiveRecord::Base.transaction(requires_new: true, &block)
    end
  end

end
