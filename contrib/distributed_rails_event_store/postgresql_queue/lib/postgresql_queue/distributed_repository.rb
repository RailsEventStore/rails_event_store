class DistributedRepository < RailsEventStoreActiveRecord::EventRepository
  def custom_lock(_collection, _include_global, _to_global)
    ary = super
    size = ary.size
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
    return ary2
  end
end
