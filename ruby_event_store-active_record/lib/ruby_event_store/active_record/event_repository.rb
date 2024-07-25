# frozen_string_literal: true

require "active_support/core_ext/array"

module RubyEventStore
  module ActiveRecord
    class EventRepository
      POSITION_SHIFT = 1

      def initialize(model_factory: WithDefaultModels.new, serializer:)
        @serializer = serializer

        @event_klass, @stream_klass = model_factory.call
        @repo_reader = EventRepositoryReader.new(@event_klass, @stream_klass, serializer)
        @index_violation_detector = IndexViolationDetector.new(@event_klass.table_name, @stream_klass.table_name)
      end

      def append_to_stream(records, stream, expected_version)
        return if records.empty?

        append_to_stream_(records, stream, expected_version)
      end

      def link_to_stream(event_ids, stream, expected_version)
        return if event_ids.empty?

        link_to_stream_(event_ids, stream, expected_version)
      end

      def delete_stream(stream)
        @stream_klass.where(stream: stream.name).delete_all
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

      def search_streams(stream_name)
        @repo_reader.search_streams(stream_name)
      end

      def update_messages(records)
        hashes = records.map { |record| upsert_hash(record, record.serialize(serializer)) }
        for_update = records.map(&:event_id)
        start_transaction do
          existing =
            @event_klass
              .where(event_id: for_update)
              .pluck(:event_id, :id, :created_at)
              .reduce({}) { |acc, (event_id, id, created_at)| acc.merge(event_id => [id, created_at]) }
          (for_update - existing.keys).each { |id| raise EventNotFound.new(id) }
          hashes.each do |h|
            h[:id] = existing.fetch(h.fetch(:event_id)).at(0)
            h[:created_at] = existing.fetch(h.fetch(:event_id)).at(1)
          end
          @event_klass.upsert_all(hashes)
        end
      end

      def streams_of(event_id)
        @repo_reader.streams_of(event_id)
      end

      def position_in_stream(event_id, stream)
        @repo_reader.position_in_stream(event_id, stream)
      end

      def global_position(event_id)
        @repo_reader.global_position(event_id)
      end

      def event_in_stream?(event_id, stream)
        @repo_reader.event_in_stream?(event_id, stream)
      end

      def specification
        "#{self.class.name} with #{::ActiveRecord::Base.connection.adapter_name} db adapter"
      end

      private

      attr_reader :serializer

      def add_to_stream(event_ids, stream, expected_version)
        last_stream_version = ->(stream_) do
          @stream_klass.where(stream: stream_.name).order("position DESC").first.try(:position)
        end
        resolved_version = expected_version.resolve_for(stream, last_stream_version)

        start_transaction do
          yield if block_given?
          in_stream =
            event_ids.map.with_index do |event_id, index|
              {
                stream: stream.name,
                position: compute_position(resolved_version, index),
                event_id: event_id,
                created_at: Time.now.utc
              }
            end
          @stream_klass.insert_all!(in_stream) unless stream.global?
        end
        self
      rescue ::ActiveRecord::RecordNotUnique => e
        raise_error(e)
      end

      def raise_error(e)
        raise EventDuplicatedInStream if detect_index_violated(e.message)
        raise WrongExpectedEventVersion
      end

      def compute_position(resolved_version, index)
        resolved_version + index + POSITION_SHIFT unless resolved_version.nil?
      end

      def detect_index_violated(message)
        @index_violation_detector.detect(message)
      end

      def insert_hash(record, serialized_record)
        {
          event_id: serialized_record.event_id,
          data: serialized_record.data,
          metadata: serialized_record.metadata,
          event_type: serialized_record.event_type,
          created_at: record.timestamp,
          valid_at: optimize_timestamp(record.valid_at, record.timestamp)
        }
      end

      def upsert_hash(record, serialized_record)
        {
          event_id: serialized_record.event_id,
          data: serialized_record.data,
          metadata: serialized_record.metadata,
          event_type: serialized_record.event_type,
          valid_at: optimize_timestamp(record.valid_at, record.timestamp)
        }
      end

      def optimize_timestamp(valid_at, created_at)
        valid_at unless valid_at.eql?(created_at)
      end

      def start_transaction(&block)
        @event_klass.transaction(requires_new: true, &block)
      end

      def link_to_stream_(event_ids, stream, expected_version)
        (
          event_ids - @event_klass.where(event_id: event_ids).pluck(:event_id)
        ).each { |id| raise EventNotFound.new(id) }
        add_to_stream(event_ids, stream, expected_version)
      end

      def append_to_stream_(records, stream, expected_version)
        hashes = []
        event_ids = []
        records.each do |record|
          hashes << insert_hash(record, record.serialize(serializer))
          event_ids << record.event_id
        end
        add_to_stream(event_ids, stream, expected_version) do
          @event_klass.insert_all!(hashes)
        end
      end
    end
  end
end
