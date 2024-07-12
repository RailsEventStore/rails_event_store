require "ruby_event_store"
require "ruby_event_store/active_record"
require_relative "../support/helpers/schema_helper"
require "benchmark"

helper = Object.new.extend(SchemaHelper)
helper.establish_database_connection
helper.drop_database
helper.load_database_schema

class Event < ::ActiveRecord::Base
  self.primary_key = :id
  self.table_name = "event_store_events"
end

class EventInStream < ::ActiveRecord::Base
  self.primary_key = :id
  self.table_name = "event_store_events_in_streams"
  belongs_to :event, primary_key: :event_id
end

Integer(ARGV.first || 1).times do
  RubyEventStore::Client.new(repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: YAML)).append(
    (1..1_000).map { RubyEventStore::Event.new },
  )
  print "."
end

mk_client = ->(reader) do
  RubyEventStore::Client.new(
    repository:
      RubyEventStore::ActiveRecord::EventRepository.new(
        serializer: YAML,
        batch_reader: reader,
        model_factory: -> { [Event, EventInStream] },
      ),
  )
end

record = ->(record) do
  record = record.event if EventInStream === record

  RubyEventStore::SerializedRecord.new(
    event_id: record.event_id,
    metadata: record.metadata,
    data: record.data,
    event_type: record.event_type,
    timestamp: record.created_at.iso8601(RubyEventStore::TIMESTAMP_PRECISION),
    valid_at: (record.valid_at || record.created_at).iso8601(RubyEventStore::TIMESTAMP_PRECISION),
  ).deserialize(YAML)
end

offset_limit = ->(spec, stream) do
  batch_reader = ->(offset, limit) { stream.offset(offset).limit(limit).map(&record) }
  RubyEventStore::BatchEnumerator.new(spec.batch_size, spec.limit, batch_reader).each
end

id_limit = ->(spec, stream) do
  start_offset_condition = ->(specification, record_id, search_in) do
    condition = "#{search_in}.id #{specification.forward? ? ">" : "<"} ?"
    [condition, record_id]
  end

  batch_reader = ->(offset_id, limit) do
    search_in =
      (
        if spec.stream.global?
          Event.table_name
        else
          EventInStream.table_name
        end
      )
    records =
      if offset_id.nil?
        stream.limit(limit)
      else
        stream.where(start_offset_condition[spec, offset_id, search_in]).limit(limit)
      end
    [records.map(&record), records.last]
  end
  RubyEventStore::ActiveRecord::BatchEnumerator.new(spec.batch_size, spec.limit, batch_reader).each
end

mk_benchmark = ->(reader) { mk_client[reader].read.each_batch { print "." } }

Benchmark.bm(14) do |x|
  x.report("offset/limit:") { mk_benchmark[offset_limit] }
  x.report("id/limit:") { mk_benchmark[id_limit] }
end
