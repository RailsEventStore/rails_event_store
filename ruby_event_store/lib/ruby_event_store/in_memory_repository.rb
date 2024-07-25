# frozen_string_literal: true

require "ostruct"
module RubyEventStore
  class InMemoryRepository
    class UnsupportedVersionAnyUsage < StandardError
      def initialize
        super <<~EOS
        Mixing expected version :any and specific position (or :auto) is unsupported.

        Read more about expected versions here:
        https://railseventstore.org/docs/v2/expected_version/
        EOS
      end
    end

    class EventInStream
      def initialize(event_id, position)
        @event_id = event_id
        @position = position
      end

      attr_reader :event_id, :position
    end

    def initialize(serializer: NULL, ensure_supported_any_usage: false)
      @serializer = serializer
      @streams = Hash.new { |h, k| h[k] = Array.new }
      @mutex = Mutex.new
      @storage = Hash.new
      @ensure_supported_any_usage = ensure_supported_any_usage
    end

    def append_to_stream(records, stream, expected_version)
      serialized_records = records.map { |record| record.serialize(serializer) }

      with_synchronize(expected_version, stream) do |resolved_version|
        ensure_supported_any_usage(resolved_version, stream)
        unless resolved_version.nil? || last_stream_version(stream).equal?(resolved_version)
          raise WrongExpectedEventVersion
        end

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
        unless resolved_version.nil? || last_stream_version(stream).equal?(resolved_version)
          raise WrongExpectedEventVersion
        end

        serialized_records.each_with_index do |serialized_record, index|
          raise EventDuplicatedInStream if has_event_in_stream?(serialized_record.event_id, stream.name)
          add_to_stream(stream, serialized_record, resolved_version, index)
        end
      end
      self
    end

    def delete_stream(stream)
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
      read_scope(spec).count
    end

    def update_messages(records)
      records.each do |record|
        read_event(record.event_id)
        serialized_record =
          Record
            .new(
              event_id: record.event_id,
              event_type: record.event_type,
              data: record.data,
              metadata: record.metadata,
              timestamp: Time.iso8601(storage.fetch(record.event_id).timestamp),
              valid_at: record.valid_at
            )
            .serialize(serializer)
        storage[record.event_id] = serialized_record
      end
    end

    def streams_of(event_id)
      streams.select { |name,| has_event_in_stream?(event_id, name) }.map { |name,| Stream.new(name) }
    end

    def search_streams(stream_name)
      streams
        .select { |name,| name.downcase.include?(stream_name.downcase) }
        .take(10)
        .reverse
        .map { |name,| Stream.new(name) }
    end

    def position_in_stream(event_id, stream)
      event_in_stream = streams[stream.name].find { |event_in_stream| event_in_stream.event_id.eql?(event_id) }
      raise EventNotFoundInStream if event_in_stream.nil?
      event_in_stream.position
    end

    def global_position(event_id)
      storage.keys.index(event_id) or raise EventNotFound.new(event_id)
    end

    def event_in_stream?(event_id, stream)
      !streams[stream.name].find { |event_in_stream| event_in_stream.event_id.eql?(event_id) }.nil?
    end

    private

    def read_scope(spec)
      serialized_records = serialized_records_of_stream(spec.stream)
      serialized_records = ordered(serialized_records, spec)
      serialized_records = serialized_records.select { |e| spec.with_ids.any? { |x| x.eql?(e.event_id) } } if spec
        .with_ids?
      serialized_records = serialized_records.select { |e| spec.with_types.any? { |x| x.eql?(e.event_type) } } if spec
        .with_types?
      serialized_records = serialized_records.reverse if spec.backward?
      serialized_records = serialized_records.drop(index_of(serialized_records, spec.start) + 1) if spec.start
      serialized_records = serialized_records.take(index_of(serialized_records, spec.stop)) if spec.stop
      serialized_records = serialized_records.take(spec.limit) if spec.limit?
      serialized_records = serialized_records.select { |sr| Time.iso8601(time_comparison_field(spec, sr)) < spec.older_than } if spec
        .older_than
      serialized_records =
        serialized_records.select { |sr| Time.iso8601(time_comparison_field(spec, sr)) <= spec.older_than_or_equal } if spec
        .older_than_or_equal
      serialized_records = serialized_records.select { |sr| Time.iso8601(time_comparison_field(spec, sr)) > spec.newer_than } if spec
        .newer_than
      serialized_records =
        serialized_records.select { |sr| Time.iso8601(time_comparison_field(spec, sr)) >= spec.newer_than_or_equal } if spec
        .newer_than_or_equal
      serialized_records
    end

    def time_comparison_field(spec, sr)
      if spec.time_sort_by_as_of?
        sr.valid_at
      else
        sr.timestamp
      end
    end

    def read_event(event_id)
      storage.fetch(event_id) { raise EventNotFound.new(event_id) }
    end

    def event_ids_of_stream(stream)
      streams.fetch(stream.name, Array.new).map(&:event_id)
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
      if @ensure_supported_any_usage
        stream_positions = streams.fetch(stream.name, Array.new).map(&:position)
        if resolved_version.nil?
          raise UnsupportedVersionAnyUsage if !stream_positions.compact.empty?
        else
          raise UnsupportedVersionAnyUsage if stream_positions.include?(nil)
        end
      end
    end

    attr_reader :streams, :mutex, :storage, :serializer
  end
end
