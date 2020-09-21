# frozen_string_literal: true

require 'ostruct'
module RubyEventStore
  class InMemoryRepository

    def initialize
      @streams = Hash.new { |h, k| h[k] = Array.new }
      @mutex   = Mutex.new
      @storage = Hash.new
    end

    def append_to_stream(records, stream, expected_version)
      records = Array(records)

      with_synchronize(expected_version, stream) do |resolved_version|
        raise WrongExpectedEventVersion unless last_stream_version(stream).equal?(resolved_version)

        records.each do |record|
          raise EventDuplicatedInStream if has_event?(record.event_id)
          storage[record.event_id] = record
          streams[stream.name] << record.event_id
        end
      end
      self
    end

    def link_to_stream(event_ids, stream, expected_version)
      records = Array(event_ids).map { |id| read_event(id) }

      with_synchronize(expected_version, stream) do |resolved_version|
        raise WrongExpectedEventVersion unless last_stream_version(stream).equal?(resolved_version)

        records.each do |record|
          raise EventDuplicatedInStream if has_event_in_stream?(record.event_id, stream.name)
          streams[stream.name] << record.event_id
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
      storage[event_ids_of_stream(stream).last]
    end

    def read(spec)
      records = read_scope(spec)
      if spec.batched?
        batch_reader = ->(offset, limit) do
          records
            .drop(offset)
            .take(limit)
        end
        BatchEnumerator.new(spec.batch_size, records.size, batch_reader).each
      elsif spec.first?
        records.first
      elsif spec.last?
        records.last
      else
        records.each
      end
    end

    def count(spec)
      read_scope(spec).count
    end

    def update_messages(records)
      records.each do |record|
        read_event(record.event_id)
        storage[record.event_id] =
          Record.new(
            event_id:   record.event_id,
            event_type: record.event_type,
            data:       record.data,
            metadata:   record.metadata,
            timestamp:  storage.fetch(record.event_id).timestamp,
          )
      end
    end

    def streams_of(event_id)
      streams
        .select { |name,| has_event_in_stream?(event_id, name) }
        .map    { |name,| Stream.new(name) }
    end

    private
    def read_scope(spec)
      records = records_of_stream(spec.stream)
      records = records.select{|e| spec.with_ids.any?{|x| x.eql?(e.event_id)}} if spec.with_ids?
      records = records.select{|e| spec.with_types.any?{|x| x.eql?(e.event_type)}} if spec.with_types?
      records = records.reverse if spec.backward?
      records = records.drop(index_of(records, spec.start) + 1) if spec.start
      records = records.take(index_of(records, spec.stop)) if spec.stop
      records = records[0...spec.limit] if spec.limit?
      records = records.select { |sr| sr.timestamp < spec.older_than } if spec.older_than
      records = records.select { |sr| sr.timestamp <= spec.older_than_or_equal } if spec.older_than_or_equal
      records = records.select { |sr| sr.timestamp > spec.newer_than } if spec.newer_than
      records = records.select { |sr| sr.timestamp >= spec.newer_than_or_equal } if spec.newer_than_or_equal
      records
    end

    def read_event(event_id)
      storage.fetch(event_id) { raise EventNotFound.new(event_id) }
    end

    def event_ids_of_stream(stream)
      streams.fetch(stream.name, Array.new)
    end

    def records_of_stream(stream)
      stream.global? ? storage.values : storage.fetch_values(*event_ids_of_stream(stream))
    end

    def last_stream_version(stream)
      event_ids_of_stream(stream).size - 1
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
      mutex.synchronize do
        resolved_version = last_stream_version(stream) if expected_version.any?
        block.call(resolved_version)
      end
    end

    def has_event_in_stream?(event_id, stream_name)
      streams.fetch(stream_name, Array.new).any? { |id| id.eql?(event_id) }
    end

    def index_of(source, event_id)
      source.index {|item| item.event_id.eql?(event_id)}
    end

    attr_reader :streams, :mutex, :storage
  end
end
