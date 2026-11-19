# frozen_string_literal: true

module RubyEventStore
  class InMemoryRepository
    class UnsupportedVersionAnyUsage < StandardError
      def initialize
        super <<~EOS
        Mixing expected version :any and specific position (or :auto) is unsupported.

        Read more about expected versions here:
        https://railseventstore.org/docs/core-concepts/expected-version
        EOS
      end
    end

    class EventInStream
      def initialize(event_id, position, hidden: false, sentinel: false)
        @event_id = event_id
        @position = position
        @hidden = hidden
        @sentinel = sentinel
      end

      attr_reader :event_id, :position

      def hidden?
        @hidden
      end

      def sentinel?
        @sentinel
      end

      def hide
        @hidden = true
      end

      def show
        @hidden = false
      end
    end

    def initialize(serializer: NULL)
      @serializer = serializer
      @streams = Hash.new { |h, k| h[k] = Array.new }
      @mutex = Mutex.new
      @storage = Hash.new
      @stream_metadata = Hash.new
      @truncation_boundaries = Hash.new
    end

    def append_to_stream(records, stream, expected_version)
      serialized_records = records.map { |record| record.serialize(serializer) }

      with_synchronize(expected_version, stream) do |resolved_version|
        ensure_supported_any_usage(resolved_version, stream)
        ensure_expected_version(resolved_version, stream)

        serialized_records.each_with_index do |serialized_record, index|
          raise EventDuplicatedInStream if has_event?(serialized_record.event_id)
          storage[serialized_record.event_id] = serialized_record
          add_to_stream(stream, serialized_record, resolved_version, index)
        end
      end
      self
    end

    def link_to_stream(event_ids, stream, expected_version)
      serialized_records = event_ids.map { |id| read_event(id) }

      with_synchronize(expected_version, stream) do |resolved_version|
        ensure_supported_any_usage(resolved_version, stream)
        ensure_expected_version(resolved_version, stream)

        serialized_records.each_with_index do |serialized_record, index|
          raise EventDuplicatedInStream if has_event_in_stream?(serialized_record.event_id, stream.name)
          add_to_stream(stream, serialized_record, resolved_version, index)
        end
      end
      self
    end

    def delete_stream(stream)
      @truncation_boundaries.delete(stream.name)
      streams.delete(stream.name)
    end

    def has_event?(event_id)
      storage.has_key?(event_id)
    end

    def last_stream_event(stream)
      last_id = event_ids_of_stream(stream).last
      storage.fetch(last_id).deserialize(serializer) if last_id
    end

    def read(spec)
      serialized_records = read_scope(spec)
      if spec.batched?
        batch_reader = ->(offset, limit) do
          serialized_records
            .drop(offset)
            .take(limit)
            .map { |serialized_record| serialized_record.deserialize(serializer) }
        end
        BatchEnumerator.new(spec.batch_size, serialized_records.size, batch_reader).each
      elsif spec.first?
        serialized_records.first&.deserialize(serializer)
      elsif spec.last?
        serialized_records.last&.deserialize(serializer)
      else
        Enumerator.new do |y|
          serialized_records.each { |serialized_record| y << serialized_record.deserialize(serializer) }
        end
      end
    end

    def count(spec)
      read_scope(spec).size # mutant:disable
    end

    def update_messages(records)
      records.each do |record|
        read_event(record.event_id)
        serialized_record =
          Record.new(
            event_id: record.event_id,
            event_type: record.event_type,
            data: record.data,
            metadata: record.metadata,
            timestamp: Time.iso8601(storage.fetch(record.event_id).timestamp),
            valid_at: record.valid_at,
          ).serialize(serializer)
        storage[record.event_id] = serialized_record
      end
    end

    def streams_of(event_id)
      streams.select { |name,| visible_event_in_stream(event_id, name) }.map { |name,| Stream.new(name) }
    end

    def position_in_stream(event_id, stream)
      event_in_stream = visible_event_in_stream(event_id, stream.name)
      raise EventNotFoundInStream if event_in_stream.nil?
      event_in_stream.position
    end

    def global_position(event_id)
      storage.keys.index(event_id) or raise EventNotFound.new(event_id)
    end

    def event_in_stream?(event_id, stream)
      !visible_event_in_stream(event_id, stream.name).nil?
    end

    def supports_native_truncation?
      true
    end

    def last_stream_version_and_tombstone(stream)
      [entries_of(stream).last&.position, stream_metadata(stream).tombstoned?]
    end

    def stream_metadata(stream)
      @stream_metadata.fetch(stream.name, StreamMetadata.none)
    end

    def append_stream_metadata(record, stream, expected_version)
      serialized_record = record.serialize(serializer)
      meta_stream = StreamMetadata.meta_stream(stream)

      mutex.synchronize do
        ensure_expected_version(expected_version.resolve_for(stream, method(:last_stream_version)), stream)
        raise EventDuplicatedInStream if has_event?(record.event_id)

        storage[record.event_id] = serialized_record
        add_to_stream(meta_stream, serialized_record, last_stream_version(meta_stream), 0)
        apply_stream_metadata(record, stream)
      end
      self
    end

    def mark_truncated(stream, batch_size)
      mutex.synchronize do
        entries_of(stream).first(truncation_boundary(stream)).reject(&:hidden?).take(batch_size).each(&:hide).size
      end
    end

    def unmark_truncated(stream, batch_size)
      mutex.synchronize do
        entries_of(stream)
          .drop(truncation_boundary(stream))
          .reverse
          .select { |entry| entry.hidden? && !entry.sentinel? }
          .take(batch_size)
          .each(&:show)
          .size
      end
    end

    private

    def apply_stream_metadata(record, stream)
      data = record.data
      case record.event_type
      when StreamMetadataEvents::StreamMetadataChanged.name
        change_stream_metadata(stream, max_count: data.fetch("max_count"), max_age: data.fetch("max_age"))
      when StreamMetadataEvents::StreamTruncated.name
        before_position = data.fetch("before_position")
        truncate(stream, before_position, entries_of(stream).count { |entry| entry.position&.<(before_position) })
      when StreamMetadataEvents::StreamSoftDeleted.name
        entries = entries_of(stream)
        truncate(stream, entries.last&.position&.succ, entries.size)
        change_stream_metadata(stream, soft_deleted_at: record.timestamp)
      when StreamMetadataEvents::StreamTombstoned.name
        change_stream_metadata(stream, tombstoned_at: record.timestamp)
        add_sentinel(stream, record.event_id)
      when StreamMetadataEvents::StreamRestored.name
        change_stream_metadata(stream, soft_deleted_at: nil, truncate_before: nil)
        @truncation_boundaries.delete(stream.name)
      end
    end

    def change_stream_metadata(stream, **attributes)
      @stream_metadata[stream.name] = stream_metadata(stream).with(**attributes)
    end

    # The hide boundary is the number of entries at the start of the stream it covers.
    def truncate(stream, before_position, covered_entries)
      truncate_before = [stream_metadata(stream).truncate_before, before_position].compact.max
      change_stream_metadata(stream, truncate_before: truncate_before)
      @truncation_boundaries[stream.name] = [truncation_boundary(stream), covered_entries].max
    end

    def truncation_boundary(stream)
      @truncation_boundaries.fetch(stream.name, 0)
    end

    def add_sentinel(stream, event_id)
      entries = entries_of(stream)
      position = entries.empty? ? 0 : entries.last.position&.succ
      streams[stream.name] << EventInStream.new(event_id, position, hidden: true, sentinel: true)
    end

    def entries_of(stream)
      streams.fetch(stream.name, Array.new)
    end

    def visible_entries_of(stream)
      entries_of(stream).reject(&:hidden?)
    end

    def visible_event_in_stream(event_id, stream_name)
      streams.fetch(stream_name, Array.new).find { |entry| !entry.hidden? && entry.event_id.eql?(event_id) }
    end

    def ensure_expected_version(resolved_version, stream)
      return if resolved_version.nil? || last_stream_version(stream).equal?(resolved_version)
      raise WrongExpectedEventVersion
    end

    def read_scope(spec)
      serialized_records = serialized_records_of_stream(spec.stream)
      serialized_records = ordered(serialized_records, spec)
      serialized_records =
        serialized_records.select { |e| spec.with_ids.any? { |x| x.eql?(e.event_id) } } if spec.with_ids?
      serialized_records =
        serialized_records.select { |e| spec.with_types.any? { |x| x.eql?(e.event_type) } } if spec.with_types?
      serialized_records = serialized_records.reverse if spec.backward?
      serialized_records = serialized_records.drop(index_of(serialized_records, spec.start) + 1) if spec.start
      serialized_records = serialized_records.take(index_of(serialized_records, spec.stop)) if spec.stop
      serialized_records =
        serialized_records.select do |sr|
          Time.iso8601(time_comparison_field(spec, sr)) < spec.older_than
        end if spec.older_than
      serialized_records =
        serialized_records.select do |sr|
          Time.iso8601(time_comparison_field(spec, sr)) <= spec.older_than_or_equal
        end if spec.older_than_or_equal
      serialized_records =
        serialized_records.select do |sr|
          Time.iso8601(time_comparison_field(spec, sr)) > spec.newer_than
        end if spec.newer_than
      serialized_records =
        serialized_records.select do |sr|
          Time.iso8601(time_comparison_field(spec, sr)) >= spec.newer_than_or_equal
        end if spec.newer_than_or_equal
      serialized_records = serialized_records.take(spec.limit) if spec.limit?
      serialized_records
    end

    def time_comparison_field(spec, sr)
      spec.time_sort_by_as_of? ? sr.valid_at : sr.timestamp
    end

    def read_event(event_id)
      storage.fetch(event_id) { raise EventNotFound.new(event_id) }
    end

    def event_ids_of_stream(stream)
      visible_entries_of(stream).map(&:event_id)
    end

    def serialized_records_of_stream(stream)
      stream.global? ? storage.values : storage.fetch_values(*event_ids_of_stream(stream))
    end

    def ordered(serialized_records, spec)
      case spec.time_sort_by
      when :as_at
        serialized_records.sort_by(&:timestamp)
      when :as_of
        serialized_records.sort_by(&:valid_at)
      else
        serialized_records
      end
    end

    def last_stream_version(stream)
      streams.fetch(stream.name, Array.new).size - 1
    end

    def with_synchronize(expected_version, stream, &block)
      resolved_version = expected_version.resolve_for(stream, method(:last_stream_version))

      # expected_version :auto assumes external lock is used
      # which makes reading stream before writing safe.
      #
      # To emulate potential concurrency issues of :auto strategy without
      # such external lock we use Thread.pass to make race
      # conditions more likely. And we only use mutex.synchronize for writing
      # not for the whole read+write algorithm.
      Thread.pass
      mutex.synchronize { block.call(resolved_version) }
    end

    def has_event_in_stream?(event_id, stream_name)
      streams.fetch(stream_name, Array.new).any? { |event_in_stream| event_in_stream.event_id.eql?(event_id) }
    end

    def index_of(source, event_id)
      index = source.index { |item| item.event_id.eql?(event_id) }
      raise EventNotFound.new(event_id) unless index

      index
    end

    def compute_position(resolved_version, index)
      resolved_version + index + 1 unless resolved_version.nil?
    end

    def add_to_stream(stream, serialized_record, resolved_version, index)
      streams[stream.name] << EventInStream.new(serialized_record.event_id, compute_position(resolved_version, index))
    end

    def ensure_supported_any_usage(resolved_version, stream)
      stream_positions = streams.fetch(stream.name, Array.new).map(&:position)
      violation =
        (resolved_version.nil? && !stream_positions.compact.empty?) ||
          (!resolved_version.nil? && stream_positions.include?(nil))

      raise UnsupportedVersionAnyUsage if violation
    end

    attr_reader :streams, :mutex, :storage, :serializer
  end
end
