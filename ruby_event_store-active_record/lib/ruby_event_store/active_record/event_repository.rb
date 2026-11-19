# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class EventRepository
      POSITION_SHIFT = 1

      def initialize(model_factory: WithDefaultModels.new, serializer:)
        @serializer = serializer
        @model_factory = model_factory
      end

      def rescue_from_double_json_serialization!
        if @serializer == JSON && json_data_type?(event_klass)
          repo_reader.instance_eval { alias __record__ record }

          repo_reader.define_singleton_method :unwrap do |column_name, payload|
            if String === payload && payload.start_with?("\{")
              warn "Double serialization of #{column_name} column detected"
              @serializer.load(payload)
            else
              payload
            end
          end

          repo_reader.define_singleton_method :record do |record|
            r = __record__(record)

            Record.new(
              event_id: r.event_id,
              metadata: unwrap("metadata", r.metadata),
              data: unwrap("data", r.data),
              event_type: r.event_type,
              timestamp: r.timestamp,
              valid_at: r.valid_at,
            )
          end
        end
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
        stream_klass.where(stream: stream.name).delete_all
      end

      def has_event?(event_id)
        repo_reader.has_event?(event_id)
      end

      def last_stream_event(stream)
        repo_reader.last_stream_event(stream)
      end

      def read(specification)
        repo_reader.read(specification)
      end

      def count(specification)
        repo_reader.count(specification)
      end

      def update_messages(records)
        hashes = records.map { |record| upsert_hash(record, record.serialize(@serializer)) }
        for_update = records.map(&:event_id)
        start_transaction do
          existing =
            event_klass
              .where(event_id: for_update)
              .pluck(:event_id, :id, :created_at)
              .reduce({}) { |acc, (event_id, id, created_at)| acc.merge(event_id => [id, created_at]) }
          (for_update - existing.keys).each { |id| raise EventNotFound.new(id) }
          hashes.each do |h|
            h[:id] = existing.fetch(h.fetch(:event_id)).at(0)
            h[:created_at] = existing.fetch(h.fetch(:event_id)).at(1)
          end
          event_klass.upsert_all(hashes)
        end
      end

      def streams_of(event_id)
        repo_reader.streams_of(event_id)
      end

      def position_in_stream(event_id, stream)
        repo_reader.position_in_stream(event_id, stream)
      end

      def global_position(event_id)
        repo_reader.global_position(event_id)
      end

      def event_in_stream?(event_id, stream)
        repo_reader.event_in_stream?(event_id, stream)
      end

      def supports_native_truncation?
        repo_reader.truncation_supported? && metadata_klass.table_exists?
      end

      def last_stream_version_and_tombstone(stream)
        position, tombstoned_at =
          stream_klass
            .joins(
              stream_table.join(metadata_table, Arel::Nodes::OuterJoin).on(
                metadata_table[:stream].eq(stream_table[:stream]),
              ).join_sources,
            )
            .where(stream: stream.name)
            .order(stream_table[:position].desc)
            .pick(stream_table[:position], metadata_table[:tombstoned_at])
        [position, !tombstoned_at.nil?]
      end

      def stream_metadata(stream)
        row = metadata_klass.find_by(stream: stream.name)
        row ? StreamMetadata.new(**StreamMetadata.members.to_h { |name| [name, row[name]] }) : StreamMetadata.none
      end

      def append_stream_metadata(record, stream, expected_version)
        start_transaction do
          highest_position, highest_id =
            stream_klass.where(stream: stream.name).pick("MAX(position)", "MAX(id)")
          check_stream_version(expected_version, highest_position, highest_id)
          append_to_stream([record], StreamMetadata.meta_stream(stream), ExpectedVersion.auto)
          materialise_metadata(record, stream, highest_position, highest_id)
        end
        self
      rescue ::ActiveRecord::RecordNotUnique => e
        raise_error(e)
      end

      def mark_truncated(stream, batch_size)
        start_transaction do
          # Without a boundary "id <= NULL" matches nothing.
          truncated_upto_id = hide_boundary(stream)
          ids =
            stream_klass
              .where(stream: stream.name, truncated_at: nil)
              .where(stream_table[:id].lteq(truncated_upto_id))
              .order(id: :asc)
              .limit(batch_size)
              .pluck(:id)
          stream_klass.where(id: ids).update_all(truncated_at: Time.now)
        end
      end

      def unmark_truncated(stream, batch_size)
        start_transaction do
          truncated_upto_id = hide_boundary(stream)
          metadata_events = stream_klass.where(stream: StreamMetadata.meta_stream(stream).name).select(:event_id)
          hidden = stream_klass.where(stream: stream.name).where.not(truncated_at: nil).where.not(event_id: metadata_events)
          hidden = hidden.where(stream_table[:id].gt(truncated_upto_id)) if truncated_upto_id

          ids = hidden.order(id: :desc).limit(batch_size).pluck(:id)
          stream_klass.where(id: ids).update_all(truncated_at: nil)
        end
      end

      private

      def add_to_stream(event_ids, stream, expected_version)
        last_stream_version = ->(stream_) do
          stream_klass.where(stream: stream_.name).order("position DESC").first.try(:position)
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
                created_at: Time.now.utc,
              }
            end
          stream_klass.insert_all!(in_stream) unless stream.global?
        end
        self
      rescue ::ActiveRecord::RecordNotUnique => e
        raise_error(e)
      end

      METADATA_COLUMNS = %i[max_count max_age truncate_before truncated_upto_id soft_deleted_at tombstoned_at].freeze
      private_constant :METADATA_COLUMNS

      def check_stream_version(expected_version, highest_position, highest_id)
        matches =
          case expected_version.version
          when Integer
            highest_position.eql?(expected_version.version)
          when :none
            highest_id.nil?
          else
            true
          end
        raise WrongExpectedEventVersion unless matches
      end

      def materialise_metadata(record, stream, highest_position, highest_id)
        current = metadata_klass.find_by(stream: stream.name)
        metadata = METADATA_COLUMNS.to_h { |column| [column, current && current[column]] }
        data = record.data

        case record.event_type
        when StreamMetadataEvents::StreamMetadataChanged.name
          metadata.merge!(max_count: data.fetch("max_count"), max_age: data.fetch("max_age"))
        when StreamMetadataEvents::StreamTruncated.name
          before_position = data.fetch("before_position")
          metadata.merge!(
            truncate_before: [metadata.fetch(:truncate_before), before_position].compact.max,
            truncated_upto_id: [
              metadata.fetch(:truncated_upto_id),
              stream_klass.where(stream: stream.name).where(stream_table[:position].lt(before_position)).maximum(:id),
            ].compact.max,
          )
        when StreamMetadataEvents::StreamSoftDeleted.name
          metadata.merge!(
            soft_deleted_at: record.timestamp,
            truncate_before: [metadata.fetch(:truncate_before), highest_position&.succ].compact.max,
            # Row ids only grow, so the highest one covers any boundary set before.
            truncated_upto_id: highest_id,
          )
        when StreamMetadataEvents::StreamTombstoned.name
          metadata[:tombstoned_at] = record.timestamp
          link_tombstone_sentinel(record, stream, highest_position, highest_id)
        when StreamMetadataEvents::StreamRestored.name
          metadata.merge!(soft_deleted_at: nil, truncate_before: nil, truncated_upto_id: nil)
        else
          return
        end

        if current
          metadata_klass.where(stream: stream.name).update_all(metadata)
        else
          metadata_klass.insert_all!([metadata.merge(stream: stream.name)])
        end
      end

      def link_tombstone_sentinel(record, stream, highest_position, highest_id)
        position = highest_position ? highest_position + POSITION_SHIFT : (0 if highest_id.nil?)
        # insert_all! sets created_at, as it records timestamps.
        stream_klass.insert_all!(
          [{ stream: stream.name, position: position, event_id: record.event_id, truncated_at: Time.now }],
        )
      end

      def hide_boundary(stream)
        metadata_klass.where(stream: stream.name).pick(:truncated_upto_id)
      end

      def raise_error(e)
        raise EventDuplicatedInStream if detect_index_violated(e.message)
        raise WrongExpectedEventVersion
      end

      def compute_position(resolved_version, index)
        resolved_version + index + POSITION_SHIFT unless resolved_version.nil?
      end

      def detect_index_violated(message)
        index_violation_detector.detect(message)
      end

      def insert_hash(record, serialized_record)
        {
          event_id: serialized_record.event_id,
          data: serialized_record.data,
          metadata: serialized_record.metadata,
          event_type: serialized_record.event_type,
          created_at: record.timestamp,
          valid_at: optimize_timestamp(record.valid_at, record.timestamp),
        }
      end

      def upsert_hash(record, serialized_record)
        {
          event_id: serialized_record.event_id,
          data: serialized_record.data,
          metadata: serialized_record.metadata,
          event_type: serialized_record.event_type,
          valid_at: optimize_timestamp(record.valid_at, record.timestamp),
        }
      end

      def optimize_timestamp(valid_at, created_at)
        valid_at unless valid_at.eql?(created_at)
      end

      def start_transaction(&block)
        event_klass.transaction(requires_new: true, &block)
      end

      def link_to_stream_(event_ids, stream, expected_version)
        (event_ids - event_klass.where(event_id: event_ids).pluck(:event_id)).each { |id| raise EventNotFound.new(id) }
        add_to_stream(event_ids, stream, expected_version)
      end

      def append_to_stream_(records, stream, expected_version)
        hashes = []
        event_ids = []
        records.each do |record|
          hashes << insert_hash(record, record.serialize(@serializer))
          event_ids << record.event_id
        end
        add_to_stream(event_ids, stream, expected_version) { event_klass.insert_all!(hashes) }
      end

      def model_klasses
        @model_klasses ||= @model_factory.call.tap do |event_model, stream_model|
          if @serializer == NULL && json_data_type?(event_model)
            warn <<~MSG
              The data or metadata column is of a JSON/B type and expects a JSON string.

              Yet the repository serializer is configured as #{@serializer} and it would not
              produce the expected JSON string.

              In ActiveRecord there's an implicit serialization to JSON for JSON/B column types
              that made it work so far. This behaviour is unfortunately also a source of undesired
              double serialization — first in the EventRepository, second in the ActiveRecord.

              In the past we've advised workarounds that introduced configuration incosistency
              with other data types and serialization formats, i.e. explicitly passing NULL serializer
              just for the JSON/B data types.

              As of now this special ActiveRecord behaviour is disabled. You should be using JSON
              serializer back again:

              RubyEventStore::ActiveRecord::EventRepository.new(serializer: JSON)
            MSG
          else
            event_model.include(SkipJsonSerialization)
            event_model.reset_column_information
          end
        end
      end

      def event_klass = model_klasses.first
      def stream_klass = model_klasses.last

      # Any subclass with the table name set reads the same rows, so mutant's superclass mutation is equivalent.
      # mutant:disable
      def metadata_klass
        @metadata_klass ||= Class.new(stream_klass.superclass) { self.table_name = "event_store_streams_metadata" }
      end

      def stream_table = stream_klass.arel_table
      def metadata_table = metadata_klass.arel_table

      def repo_reader
        @repo_reader ||= EventRepositoryReader.new(event_klass, stream_klass, @serializer)
      end

      def index_violation_detector
        @index_violation_detector ||= IndexViolationDetector.new(event_klass.table_name, stream_klass.table_name)
      end

      def json_data_type?(klass)
        %i[data metadata].any? { |attr| klass.column_for_attribute(attr).type.start_with?("json") }
      end
    end
  end
end
