# frozen_string_literal: true

require "forwardable"
require "securerandom"

module RubyEventStore
  # Adds stream metadata to a repository: retention settings, truncation, soft delete, restore
  # and tombstone. Opt-in: wrap the repository passed to the client.
  #
  #   RubyEventStore::Client.new(repository: RubyEventStore::StreamMetadataAwareRepository.new(repository))
  #
  # Reads go to the repository unchanged: a repository with native support (see the
  # "stream metadata" lint) leaves hidden entries out by itself. On any other repository
  # truncate, soft delete and restore raise StreamMetadataNotSupported, while retention settings
  # and tombstones still work there.
  #
  # Stream names starting with "$" are reserved: "$$<name>" holds the metadata events of <name>.
  #
  # Each metadata method takes the metadata of the event it writes: the client passes it enriched
  # as for publish (request metadata, correlation_id, timestamp, valid_at); the decorator's clock
  # stamps the event when there is no timestamp.
  #
  # Metadata events are only appended by default. With publish_metadata_events: true each one is
  # also given, once the operation is complete, to the block the client passes, which hands it to
  # the subscribed handlers. Mind a handler that writes to the stream in reaction.
  class StreamMetadataAwareRepository
    extend Forwardable

    RESERVED_PREFIX = "$"
    NATIVE_TIER = %i[
      supports_native_truncation?
      last_stream_version_and_tombstone
      append_stream_metadata
      mark_truncated
      unmark_truncated
    ].freeze
    private_constant :NATIVE_TIER
    StreamRestore = Data.define(:restored, :missing)
    EMPTY_HASH = {}.freeze
    private_constant :EMPTY_HASH

    def_delegators :repository,
                   :has_event?,
                   :last_stream_event,
                   :read,
                   :count,
                   :update_messages,
                   :streams_of,
                   :position_in_stream,
                   :global_position,
                   :event_in_stream?

    def initialize(
      repository,
      registry: StreamMetadataRegistry.new(repository),
      batch_size: 1_000,
      clock: -> { Time.now.utc.round(TIMESTAMP_PRECISION) },
      publish_metadata_events: false
    )
      @repository = repository
      @registry = registry
      @batch_size = batch_size
      @clock = clock
      @publish_metadata_events = publish_metadata_events
      @native = repository.respond_to?(:supports_native_truncation?) && repository.supports_native_truncation?
    end

    def append_to_stream(records, stream, expected_version)
      ensure_not_reserved(stream)
      repository.append_to_stream(records, stream, writable_version(stream, expected_version))
    end

    def link_to_stream(event_ids, stream, expected_version)
      ensure_not_reserved(stream)
      repository.link_to_stream(event_ids, stream, writable_version(stream, expected_version))
    end

    # Deletes the stream's entries as the repository does. A tombstoned stream is refused, as
    # deleting would drop its sentinel. On a truncated or soft deleted stream the deletion is
    # followed by StreamRestored, so that the metadata no longer describes entries that are gone.
    def delete_stream(stream, metadata: EMPTY_HASH, &published)
      return repository.delete_stream(stream) if stream.global? || stream.name.start_with?(RESERVED_PREFIX)
      stream_metadata = stream_metadata(stream)
      raise StreamTombstoned if stream_metadata.tombstoned?
      result = repository.delete_stream(stream)
      if native && (stream_metadata.soft_deleted? || !stream_metadata.truncate_before.nil?)
        publish(write(StreamMetadataEvents::StreamRestored, stream, ExpectedVersion.any, metadata), &published)
      end
      result
    end

    def stream_metadata(stream)
      ensure_metadata_stream(stream)
      native ? repository.stream_metadata(stream) : stream_metadata_from_events(stream)
    end

    def set_stream_metadata(stream, max_count:, max_age:, expected_version:, metadata: EMPTY_HASH, &published)
      ensure_metadata_stream(stream)
      ensure_positive_or_nil(max_count)
      ensure_positive_or_nil(max_age)
      record =
        write(
          StreamMetadataEvents::StreamMetadataChanged,
          stream,
          expected_version,
          metadata,
          "max_count" => max_count,
          "max_age" => max_age,
        )
      publish(record, &published)
    end

    def truncate_stream(stream, before:, expected_version:, metadata: EMPTY_HASH, &published)
      ensure_truncation(stream)
      raise InvalidStreamMetadata unless before.instance_of?(Integer) && !before.negative?
      record =
        write(StreamMetadataEvents::StreamTruncated, stream, expected_version, metadata, "before_position" => before)
      mark_truncated(stream)
      publish(record, &published)
    end

    def soft_delete_stream(stream, expected_version:, metadata: EMPTY_HASH, &published)
      ensure_truncation(stream)
      record = write(StreamMetadataEvents::StreamSoftDeleted, stream, expected_version, metadata)
      mark_truncated(stream)
      publish(record, &published)
    end

    def restore_stream(stream, expected_version:, metadata: EMPTY_HASH, &published)
      ensure_truncation(stream)
      record = write(StreamMetadataEvents::StreamRestored, stream, expected_version, metadata)
      restored = 0
      while (shown = repository.unmark_truncated(stream, batch_size)).positive?
        restored += shown
      end
      publish(record, &published)
      StreamRestore.new(restored: restored, missing: missing_entries(stream))
    end

    def tombstone_stream(stream, expected_version:, metadata: EMPTY_HASH, &published)
      raise StreamTombstoned if stream_metadata(stream).tombstoned?
      record = write(StreamMetadataEvents::StreamTombstoned, stream, expected_version, metadata)
      registry.tombstone(stream)
      publish(record, &published)
    end

    def method_missing(method_name, *arguments, **keyword_arguments, &block)
      if respond_to?(method_name)
        repository.public_send(method_name, *arguments, **keyword_arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private)
      !NATIVE_TIER.include?(method_name) && repository.respond_to?(method_name)
    end

    private

    attr_reader :repository, :registry, :batch_size, :clock, :native, :publish_metadata_events

    def writable_version(stream, expected_version)
      return expected_version if stream.global?
      return auto_version(stream) if native && expected_version.auto?
      raise StreamTombstoned if registry.tombstoned?(stream)
      expected_version
    end

    def auto_version(stream)
      last_position, tombstoned = repository.last_stream_version_and_tombstone(stream)
      raise StreamTombstoned if tombstoned
      ExpectedVersion.new(last_position || ExpectedVersion::POSITION_DEFAULT)
    end

    def write(event_class, stream, expected_version, metadata, **data)
      record = metadata_record(event_class, stream, data, metadata)
      if native
        repository.append_stream_metadata(record, stream, expected_version)
      else
        ensure_expected_version(stream, expected_version)
        repository.append_to_stream([record], StreamMetadata.meta_stream(stream), ExpectedVersion.any)
      end
      record
    end

    def publish(record)
      yield record if publish_metadata_events && block_given?
      self
    end

    def metadata_record(event_class, stream, data, metadata)
      timestamp = metadata.fetch(:timestamp) { clock.call }
      Record.new(
        event_id: SecureRandom.uuid,
        event_type: event_class.name,
        data: { "stream" => stream.name }.merge(data),
        metadata: metadata.except(:timestamp, :valid_at),
        timestamp: timestamp,
        valid_at: metadata.fetch(:valid_at, timestamp),
      )
    end

    def mark_truncated(stream)
      while repository.mark_truncated(stream, batch_size).positive?
      end
    end

    def missing_entries(stream)
      last_position, tombstoned = repository.last_stream_version_and_tombstone(stream)
      return if last_position.nil?
      present = count_of(stream)
      present += 1 if tombstoned
      last_position.succ - present
    end

    def ensure_expected_version(stream, expected_version)
      last_version = count_of(stream).pred
      resolved_version = expected_version.resolve_for(stream, ->(_) { last_version })
      raise WrongExpectedEventVersion unless resolved_version.nil? || resolved_version.equal?(last_version)
    end

    # Reading through self delegates to the repository, so mutant's self mutation is equivalent.
    # mutant:disable
    def count_of(stream)
      repository.count(Specification.new(nil).stream(stream.name).result)
    end

    # mutant:disable (see count_of)
    def records_of(stream)
      repository.read(Specification.new(nil).stream(stream.name).result)
    end

    def stream_metadata_from_events(stream)
      records_of(StreamMetadata.meta_stream(stream)).reduce(StreamMetadata.none) do |metadata, record|
        case record.event_type
        when StreamMetadataEvents::StreamMetadataChanged.name
          metadata.with(max_count: record.data.fetch("max_count"), max_age: record.data.fetch("max_age"))
        when StreamMetadataEvents::StreamTombstoned.name
          metadata.with(tombstoned_at: record.timestamp)
        else
          metadata
        end
      end
    end

    def ensure_not_reserved(stream)
      raise ReservedInternalName if !stream.global? && stream.name.start_with?(RESERVED_PREFIX)
    end

    def ensure_metadata_stream(stream)
      raise InvalidStreamMetadata if stream.global?
      ensure_not_reserved(stream)
    end

    def ensure_truncation(stream)
      raise StreamMetadataNotSupported unless native
      ensure_metadata_stream(stream)
    end

    def ensure_positive_or_nil(value)
      raise InvalidStreamMetadata unless value.nil? || (value.instance_of?(Integer) && value.positive?)
    end
  end
end
