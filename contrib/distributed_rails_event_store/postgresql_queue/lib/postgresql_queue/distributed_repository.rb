require 'rails_event_store_active_record'

class DistributedRepository < RailsEventStoreActiveRecord::EventRepository
  def fill_ids(in_stream)
    size = in_stream.size
    s = <<-SQL
      SELECT
        clock_timestamp() as t1,
        pg_advisory_lock(0) as getGlobalLock,
        nextval('event_store_events_in_streams_id_seq') as c1,
        currval('event_store_events_in_streams_id_seq') as c2,
        pg_advisory_xact_lock(currval('event_store_events_in_streams_id_seq')) as eid,
        setval('event_store_events_in_streams_id_seq', currval('event_store_events_in_streams_id_seq') + #{size-1}),
        pg_advisory_unlock(0) as releaseGlobalLock,
        clock_timestamp() as t2
    SQL
    result = ActiveRecord::Base.
      connection.
      execute(s).
      each.
      to_a.
      first
    result.fetch("c1") == result.fetch("c2") or raise "err1"
    range = result.fetch("c1")..result.fetch("setval")
    ary2 = range.to_a
    ary2.size == size or raise "err2"
    ary2.each.with_index do |id, index|
      in_stream[index][:id] = id
    end
  end
end
