# frozen_string_literal: true
require 'base64'
require 'ruby_event_store/event'

module AggregateRoot
  class SnapshotRepository
    DEFAULT_SNAPSHOT_INTERVAL = 100.freeze
    SNAPSHOT_STREAM_PATTERN = ->(base_stream_name) { "#{base_stream_name}_snapshots" }
    NotRestorableSnapshot = Class.new(StandardError)
    NotDumpableEvent = Class.new(StandardError)

    def initialize(event_store, interval = DEFAULT_SNAPSHOT_INTERVAL)
      raise ArgumentError, 'interval must be an Integer' unless interval.instance_of?(Integer)
      raise ArgumentError, 'interval must be greater than 0' unless interval > 0
      @event_store = event_store
      @interval = interval
    end

    Snapshot = Class.new(RubyEventStore::Event)

    def load(aggregate, stream_name)
      last_snapshot = load_snapshot_event(stream_name)
      query = event_store.read.stream(stream_name)
      if last_snapshot
        begin
          aggregate = load_marshal(last_snapshot)
        rescue NotRestorableSnapshot
        else
          aggregate.version = last_snapshot.data.fetch(:version)
          query = query.from(last_snapshot.data.fetch(:last_event_id))
        end
      end
      query.reduce { |_, ev| aggregate.apply(ev) }
      aggregate.version = aggregate.version + aggregate.unpublished_events.count
      aggregate
    end

    def store(aggregate, stream_name)
      events = aggregate.unpublished_events.to_a
      event_store.publish(events,
                          stream_name: stream_name,
                          expected_version: aggregate.version)

      aggregate.version = aggregate.version + events.count

      if time_for_snapshot?(aggregate.version, events.size)
        begin
          publish_snapshot_event(aggregate, stream_name, events.last.event_id)
        rescue NotDumpableEvent
        end
      end
    end

    private

    attr_reader :event_store, :interval

    def publish_snapshot_event(aggregate, stream_name, last_event_id)
      event_store.publish(
        Snapshot.new(
          data: { marshal: build_marshal(aggregate), last_event_id: last_event_id, version: aggregate.version }
        ),
        stream_name: SNAPSHOT_STREAM_PATTERN.(stream_name)
      )
    end

    def build_marshal(aggregate)
      Marshal.dump(aggregate)
    rescue TypeError
      raise NotDumpableEvent
    end

    def load_snapshot_event(stream_name)
      event_store.read.stream(SNAPSHOT_STREAM_PATTERN.(stream_name)).last
    end

    def load_marshal(snpashot_event)
      Marshal.load(snpashot_event.data.fetch(:marshal))
    rescue TypeError, ArgumentError
      raise NotRestorableSnapshot
    end

    def time_for_snapshot?(aggregate_version, published_events)
      rest = (aggregate_version + 1) % interval
      published_events > rest
    end
  end
end