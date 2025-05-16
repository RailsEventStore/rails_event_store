# frozen_string_literal: true

require "ruby_event_store/event"

module AggregateRoot
  class SnapshotRepository
    DEFAULT_SNAPSHOT_INTERVAL = 100.freeze
    SNAPSHOT_STREAM_PATTERN = ->(base_stream_name) { "#{base_stream_name}_snapshots" }
    NotRestorableSnapshot = Class.new(StandardError)
    NotDumpableAggregateRoot = Class.new(StandardError)

    def initialize(event_store, interval = DEFAULT_SNAPSHOT_INTERVAL)
      raise ArgumentError, "interval must be an Integer" unless interval.instance_of?(Integer)
      raise ArgumentError, "interval must be greater than 0" unless interval > 0
      @event_store = event_store
      @interval = interval
      @error_handler = ->(_) {}
    end

    attr_writer :error_handler

    Snapshot = Class.new(RubyEventStore::Event)

    def load(aggregate, stream_name)
      last_snapshot = load_snapshot_event(stream_name)
      query = event_store.read.stream(stream_name)
      if last_snapshot
        begin
          aggregate = load_marshal(last_snapshot)
        rescue NotRestorableSnapshot => e
          error_handler.(e)
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
      event_store.publish(events, stream_name: stream_name, expected_version: aggregate.version)

      aggregate.version = aggregate.version + events.count

      if time_for_snapshot?(aggregate.version, events.size)
        begin
          publish_snapshot_event(aggregate, stream_name, events.last.event_id)
        rescue NotDumpableAggregateRoot => e
          error_handler.(e)
        end
      end
    end

    private

    attr_reader :event_store, :interval, :error_handler

    def publish_snapshot_event(aggregate, stream_name, last_event_id)
      event_store.publish(
        Snapshot.new(
          data: {
            marshal: build_marshal(aggregate),
            last_event_id: last_event_id,
            version: aggregate.version,
          },
        ),
        stream_name: SNAPSHOT_STREAM_PATTERN.(stream_name),
      )
    end

    def build_marshal(aggregate)
      Marshal.dump(aggregate)
    rescue TypeError
      raise NotDumpableAggregateRoot,
            "#{aggregate.class} cannot be dumped.
It may be caused by instance variables being: bindings, procedure or method objects, instances of class IO, or singleton objects.
Snapshot skipped."
    end

    def load_snapshot_event(stream_name)
      event_store.read.stream(SNAPSHOT_STREAM_PATTERN.(stream_name)).last
    end

    def load_marshal(snpashot_event)
      Marshal.load(snpashot_event.data.fetch(:marshal))
    rescue TypeError, ArgumentError
      raise NotRestorableSnapshot,
            "Aggregate root cannot be restored from the last snapshot (event id: #{snpashot_event.event_id}).
It may be caused by aggregate class rename or Marshal version mismatch.
Loading aggregate based on the whole stream."
    end

    def time_for_snapshot?(aggregate_version, just_published_events)
      events_in_stream = aggregate_version + 1
      events_since_time_for_snapshot = events_in_stream % interval
      just_published_events > events_since_time_for_snapshot
    end
  end
end
