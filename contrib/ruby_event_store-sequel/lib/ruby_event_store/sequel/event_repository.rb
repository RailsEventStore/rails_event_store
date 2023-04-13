# frozen_string_literal: true

module RubyEventStore
  module Sequel
    class EventRepository
      def initialize(sequel:, serializer:)
        @serializer = serializer
        @index_violation_detector = IndexViolationDetector.new("event_store_events", "event_store_events_in_streams")
        @db = sequel
        @db.timezone = :utc
      end

      attr_reader :index_violation_detector

      def append_to_stream(records, stream, expected_version)
        resolved_version = resolved_version(expected_version, stream)

        @db.transaction do
          records.map.with_index do |r, index|
            sr = r.serialize(@serializer)

            @db[:event_store_events].insert(
              event_id: sr.event_id,
              event_type: sr.event_type,
              data: sr.data,
              metadata: sr.metadata,
              created_at: r.timestamp,
              valid_at: r.valid_at
            )
            unless stream.global?
              @db[:event_store_events_in_streams].insert(
                event_id: sr.event_id,
                stream: stream.name,
                created_at: Time.now.utc,
                position: resolved_version ? resolved_version + index + 1 : nil
              )
            end
          end
        end
        self
      rescue ::Sequel::UniqueConstraintViolation => ex
        raise EventDuplicatedInStream if index_violation_detector.detect(ex.message)
        raise WrongExpectedEventVersion
      end

      def link_to_stream(event_ids, stream, expected_version)
        (event_ids - @db[:event_store_events].select(:event_id).where(event_id: event_ids).map { |e| e[:event_id] })
          .each { |id| raise EventNotFound.new(id) }

        resolved_version = resolved_version(expected_version, stream)

        @db.transaction do
          event_ids.map.with_index do |event_id, index|
            @db[:event_store_events_in_streams].insert(
              event_id: event_id,
              stream: stream.name,
              created_at: Time.now.utc,
              position: resolved_version ? resolved_version + index + 1 : nil
            )
          end
        end
        self
      rescue ::Sequel::UniqueConstraintViolation => ex
        raise EventDuplicatedInStream if index_violation_detector.detect(ex.message)
        raise WrongExpectedEventVersion
      end

      def position_in_stream(event_id, stream); end

      def global_position(event_id); end

      def event_in_stream?(event_id, stream); end

      def delete_stream(stream)
        @db[:event_store_events_in_streams].where(stream: stream.name).delete
      end

      def has_event?(event_id)
        @db[:event_store_events].where(event_id: event_id).any?
      end

      def last_stream_event(stream)
        row = @db[:event_store_events_in_streams].where(stream: stream.name).order(:position, :id).last
        return row if row.nil?
        event = @db[:event_store_events].where(event_id: row[:event_id]).first
        SerializedRecord
          .new(
            event_id: event[:event_id],
            event_type: event[:event_type],
            data: event[:data],
            metadata: event[:metadata],
            timestamp: event[:created_at].iso8601(TIMESTAMP_PRECISION),
            valid_at: event[:valid_at].iso8601(TIMESTAMP_PRECISION)
          )
          .deserialize(@serializer)
      end

      def read(specification)
        if specification.batched?
          stream = read_(specification)
          batch_reader = ->(offset, limit) { stream.offset(offset).limit(limit).map(&method(:record)) }
          RubyEventStore::BatchEnumerator.new(specification.batch_size, specification.limit, batch_reader).each
        elsif specification.first?
          record_ = read_(specification).first
          record(record_) if record_
        elsif specification.last?
          record_ = read_(specification).last
          record(record_) if record_
        else
          read_(specification).map { |h| record(h) }.each
        end
      end

      def count(specification)
        read_(specification).count
      end

      def update_messages(records); end

      def streams_of(event_id)
        @db[:event_store_events_in_streams].where(event_id: event_id).map { |h| Stream.new(h[:stream]) }
      end

      private

      def record(h)
        SerializedRecord
          .new(
            event_id: h[:event_id],
            event_type: h[:event_type],
            data: h[:data],
            metadata: h[:metadata],
            timestamp: h[:created_at].iso8601(TIMESTAMP_PRECISION),
            valid_at: h[:valid_at].iso8601(TIMESTAMP_PRECISION)
          )
          .deserialize(@serializer)
      end

      def read_(specification)
        specification.stream.global? ? read_from_global_stream(specification) : read_from_specific_stream(specification)
      end

      def resolved_version(expected_version, stream)
        expected_version.resolve_for(
          stream,
          ->(stream) do
            @db[:event_store_events_in_streams]
              .select(:position)
              .where(stream: stream.name)
              .order(:position)
              .last
              &.fetch(:position)
          end
        )
      end

      def read_from_specific_stream(specification)
        dataset =
          @db[:event_store_events]
            .join(:event_store_events_in_streams, event_id: :event_id)
            .select(
              ::Sequel[:event_store_events][:event_id],
              :event_type,
              :data,
              :metadata,
              ::Sequel[:event_store_events][:created_at],
              :valid_at
            )
            .where(stream: specification.stream.name)
            .order(::Sequel[:event_store_events_in_streams][:id])

        dataset = dataset.where(event_type: specification.with_types) if specification.with_types?
        dataset = dataset.where(::Sequel[:event_store_events][:event_id] => specification.with_ids) if specification
          .with_ids?

        if specification.start
          condition = "event_store_events_in_streams.id #{specification.forward? ? ">" : "<"} ?"
          dataset =
            dataset.where(::Sequel.lit(condition, find_event_id(specification.start, specification.stream.name)))
        end

        if specification.stop
          condition = "event_store_events_in_streams.id #{specification.forward? ? "<" : ">"} ?"
          dataset = dataset.where(::Sequel.lit(condition, find_event_id(specification.stop, specification.stream.name)))
        end

        if specification.older_than
          dataset = dataset.where(::Sequel.lit("#{time_comparison_field(specification)} < ?", specification.older_than))
        end

        if specification.older_than_or_equal
          dataset =
            dataset.where(
              ::Sequel.lit("#{time_comparison_field(specification)} <= ?", specification.older_than_or_equal)
            )
        end

        if specification.newer_than
          dataset = dataset.where(::Sequel.lit("#{time_comparison_field(specification)} > ?", specification.newer_than))
        end

        if specification.newer_than_or_equal
          dataset =
            dataset.where(
              ::Sequel.lit("#{time_comparison_field(specification)} >= ?", specification.newer_than_or_equal)
            )
        end

        dataset = dataset.order(::Sequel[:event_store_events][:created_at]) if specification.time_sort_by_as_at?
        dataset = dataset.order(::Sequel.lit(coalesced_date)) if specification.time_sort_by_as_of?
        dataset = dataset.limit(specification.limit) if specification.limit?
        dataset = dataset.order(::Sequel[:event_store_events_in_streams][:id]).reverse if specification.backward?

        dataset
      end

      def find_event_id(specification_event_id, specification_stream_name)
        @db[:event_store_events_in_streams]
          .select(:id)
          .where(event_id: specification_event_id, stream: specification_stream_name)
          .first[
          :id
        ]
      end

      def read_from_global_stream(specification)
        dataset =
          @db[:event_store_events].select(:event_id, :event_type, :data, :metadata, :created_at, :valid_at).order(:id)

        dataset = dataset.where(event_type: specification.with_types) if specification.with_types?
        dataset = dataset.where(event_id: specification.with_ids) if specification.with_ids?

        if specification.start
          id = @db[:event_store_events].select(:id).where(event_id: specification.start).first[:id]
          condition = "event_store_events.id #{specification.forward? ? ">" : "<"} ?"

          dataset = dataset.where(::Sequel.lit(condition, id))
        end

        if specification.stop
          id = @db[:event_store_events].select(:id).where(event_id: specification.stop).first[:id]
          condition = "event_store_events.id #{specification.forward? ? "<" : ">"} ?"

          dataset = dataset.where(::Sequel.lit(condition, id))
        end

        if specification.older_than
          dataset = dataset.where(::Sequel.lit("#{time_comparison_field(specification)} < ?", specification.older_than))
        end

        if specification.older_than_or_equal
          dataset =
            dataset.where(
              ::Sequel.lit("#{time_comparison_field(specification)} <= ?", specification.older_than_or_equal)
            )
        end

        if specification.newer_than
          dataset = dataset.where(::Sequel.lit("#{time_comparison_field(specification)} > ?", specification.newer_than))
        end

        if specification.newer_than_or_equal
          dataset =
            dataset.where(
              ::Sequel.lit("#{time_comparison_field(specification)} >= ?", specification.newer_than_or_equal)
            )
        end

        dataset = dataset.order(:created_at) if specification.time_sort_by_as_at?
        dataset = dataset.order(:valid_at) if specification.time_sort_by_as_of?
        dataset = dataset.limit(specification.limit) if specification.limit?
        dataset = dataset.order(::Sequel[:event_store_events][:id]) unless specification.time_sort_by
        dataset = dataset.reverse if specification.backward?

        dataset
      end

      def coalesced_date
        "COALESCE(event_store_events.valid_at, event_store_events.created_at)"
      end

      def time_comparison_field(specification)
        specification.time_sort_by_as_of? ? coalesced_date : "event_store_events.created_at"
      end
    end
  end
end
